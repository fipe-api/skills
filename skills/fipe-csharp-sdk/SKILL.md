---
name: fipe-csharp-sdk
description: Help a developer add FIPE vehicle prices to a .NET application with the official C# SDK (NuGet package Fipe.Api.Br). Use when the user writes C# or .NET code that must get Brazilian vehicle prices, brands, models, years, FIPE codes or price history, or mentions "fipe c# sdk", "Fipe.Api.Br", "FipeClient", or "tabela FIPE em .NET".
---

# FIPE C# SDK

The SDK is a client for the FIPE REST API (`https://fipe.api.br/api/v2`). The package targets `netstandard2.0`. It depends on `System.Text.Json` 10, which supports .NET 8 or later and .NET Framework 4.6.2 or later. On .NET 7 or earlier, the build shows warnings.

## Install

```sh
dotnet add package Fipe.Api.Br
```

```csharp
using Fipe.Api.Br;
```

## Procedure

1. Read the code of the user's project before you write code. Use the same style for DI, configuration, logs and tests.
2. In an ASP.NET Core or other DI application, register the client with `IHttpClientFactory`. In other applications, create one `FipeClient` and use it again. Do not create a client for each request.
3. Read the subscription token from configuration (for example `IConfiguration["Fipe:SubscriptionToken"]` or the `FIPE_SUBSCRIPTION_TOKEN` environment variable). Do not write a token in the code.
4. Give a `CancellationToken` to each call.
5. Write the code with the methods in the API map below. Do not call the REST API directly when the SDK has a method for it.
6. Handle the errors in "Errors". Always handle 402 when the code uses a past reference month or the history.
7. Write tests with a stub `HttpMessageHandler` and the `baseUrl` argument. Tests must not call the live API.
8. Run `dotnet build` and `dotnet test`.

For tested code (lookup by name, price parsing, retry, reference months, tests), read [references/recipes.md](references/recipes.md).

## Client

Without DI:

```csharp
var client = new FipeClient(subscriptionToken: Environment.GetEnvironmentVariable("FIPE_SUBSCRIPTION_TOKEN"));
```

With DI:

```csharp
builder.Services.AddHttpClient(nameof(FipeClient), http => http.Timeout = TimeSpan.FromSeconds(10));
builder.Services.AddTransient(sp => new FipeClient(
    sp.GetRequiredService<IHttpClientFactory>().CreateClient(nameof(FipeClient)),
    subscriptionToken: builder.Configuration["Fipe:SubscriptionToken"]));
```

`services.AddHttpClient<FipeClient>()` does not set the token, because the DI container cannot fill the `subscriptionToken` argument. Use the factory form above when you need a token.

| Constructor argument | Use |
| --- | --- |
| `httpClient` | The `HttpClient` for requests. The SDK does not dispose it. |
| `subscriptionToken` | Sends the `X-Subscription-Token` header. `null` or empty sends no header. |
| `baseUrl` | Changes the base URL. Use it in tests. |

## API map

All methods are async and accept `int? reference = null` (except `GetReferencesAsync`) and `CancellationToken cancellationToken = default`. Vehicle types are `VehicleType.Cars`, `VehicleType.Motorcycles` and `VehicleType.Trucks`.

| Method | Returns | REST path |
| --- | --- | --- |
| `GetReferencesAsync()` | `IReadOnlyList<Reference>` | `/references` |
| `GetBrandsAsync(vt)` | `IReadOnlyList<Brand>` | `/{vt}/brands` |
| `GetModelsAsync(vt, brand)` | `IReadOnlyList<Model>` | `/{vt}/brands/{brand}/models` |
| `GetYearsAsync(vt, brand, model)` | `IReadOnlyList<Year>` | `/{vt}/brands/{brand}/models/{model}/years` |
| `GetVehicleAsync(vt, brand, model, year)` | `Vehicle` | `/{vt}/brands/{brand}/models/{model}/years/{year}` |
| `GetYearsByBrandAsync(vt, brand)` | `IReadOnlyList<Year>` | `/{vt}/brands/{brand}/years` |
| `GetModelsByBrandYearAsync(vt, brand, year)` | `IReadOnlyList<Model>` | `/{vt}/brands/{brand}/years/{year}/models` |
| `GetYearsByFipeCodeAsync(vt, code)` | `IReadOnlyList<Year>` | `/{vt}/{code}/years` |
| `GetVehicleByFipeCodeAsync(vt, code, year)` | `Vehicle` | `/{vt}/{code}/years/{year}` |
| `GetHistoryByFipeCodeAsync(vt, code, year)` | `Vehicle` | `/{vt}/{code}/years/{year}/history` |

Use named arguments for `reference` and `cancellationToken`, for example `GetBrandsAsync(VehicleType.Cars, reference: 337, cancellationToken: ct)`.

The SDK has no method for license plates.

## Data rules

- **Codes are strings.** Brand, model and year codes are strings, for example `"59"`, `"5940"`, `"2014-3"`. `Reference.Code` is a string, but the `reference` argument is an `int?`. Use `int.Parse`.
- **Year code.** The format is `<year>-<fuel>`. Read the fuel from `Year.Name` or `Vehicle.Fuel`. Do not decode the fuel number.
- **Zero KM.** `Vehicle.ModelYear == 32000` means a new vehicle. Show "Zero KM" to users, not `32000`.
- **Price is a string.** `Vehicle.Price` has the Brazilian format, for example `"R$ 17.322,00"`. To calculate, parse it to `decimal`. Do not use `double` for money.
- **Reference codes are not in sequence.** Get the code of a month from `GetReferencesAsync`. Do not calculate a code from a date. The first item is the latest month.
- **History.** `GetHistoryByFipeCodeAsync` fills `Vehicle.PriceHistory`. `Vehicle.Price` and `Vehicle.ReferenceMonth` are empty in this response.
- **`Vehicle.VehicleTypeCode`** is a number (`1` for cars), not a `VehicleType`.

## Free tier and subscription

| Item | Without token | With token |
| --- | --- | --- |
| Reference months | The 3 latest months only | All months |
| `GetHistoryByFipeCodeAsync` | The 3 latest months only | Full history |
| Request limit | 500 requests in each period. The `x-ratelimit-reset` response header gives the seconds to the reset. | Higher limit |

A past month outside the free window returns status 402 for all endpoints.

## Errors

A status that is not a success throws `FipeApiException` with `StatusCode` and `Body`.

| Status | Catch with | Action |
| --- | --- | --- |
| 404 | `catch (FipeApiException ex) when (ex.IsNotFound)` | The brand, model, year or FIPE code does not exist for that month. Do not retry. |
| 429 | `catch (FipeApiException ex) when (ex.IsRateLimited)` | Retry with backoff, or use a token. |
| 402 | `catch (FipeApiException ex) when (ex.StatusCode == HttpStatusCode.PaymentRequired)` | The month or the history needs a subscription. Do not retry. Tell the user. |

## Performance

- FIPE prices change one time each month. Cache the responses, for example with `IMemoryCache`. Use the reference code and the request path as the cache key.
- Brand and model lists are large and change slowly. Cache them for the whole reference month.
- Do not get the full chain (brands, models, years, price) for each request when you already have the FIPE code. Use `GetVehicleByFipeCodeAsync`.
