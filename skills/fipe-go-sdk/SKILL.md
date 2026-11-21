---
name: fipe-go-sdk
description: Help a developer add FIPE vehicle prices to a Go application with the official Go SDK (github.com/fipe-api/go-sdk). Use when the user writes Go code that must get Brazilian vehicle prices, brands, models, years, FIPE codes or price history, or mentions "fipe go sdk", "tabela FIPE em Go", or imports github.com/fipe-api/go-sdk.
---

# FIPE Go SDK

The SDK is a client for the FIPE REST API (`https://fipe.api.br/api/v2`). It has no dependencies. It needs Go 1.22 or later.

## Install

```sh
go get github.com/fipe-api/go-sdk
```

Import it with the name `fipe`:

```go
import fipe "github.com/fipe-api/go-sdk"
```

## Procedure

1. Read the code of the user's project before you write code. Use the same style for errors, logs, configuration and tests.
2. Create one `*fipe.Client` and use it again for all requests. Do not create a client for each request.
3. Read the subscription token from configuration (for example the `FIPE_SUBSCRIPTION_TOKEN` environment variable). Do not write a token in the code.
4. Give a `context.Context` with a timeout to each call.
5. Write the code with the methods in the API map below. Do not call the REST API directly when the SDK has a method for it.
6. Handle the errors in "Errors". Always handle 402 when the code uses a past reference month or the history.
7. Write tests with `fipe.WithBaseURL` and `httptest.Server`. Tests must not call the live API.
8. Run `go vet ./...` and `go test ./...`.

For tested code (lookup by name, price parsing, retry, reference months, tests), read [references/recipes.md](references/recipes.md).

## Client

```go
client := fipe.New(
	fipe.WithSubscriptionToken(os.Getenv("FIPE_SUBSCRIPTION_TOKEN")),
	fipe.WithHTTPClient(&http.Client{Timeout: 10 * time.Second}),
)
```

| Option | Use |
| --- | --- |
| `fipe.WithSubscriptionToken(string)` | Sends the `X-Subscription-Token` header. An empty string sends no header. |
| `fipe.WithHTTPClient(*http.Client)` | Sets the HTTP client. The default is `http.DefaultClient`, which has no timeout. |
| `fipe.WithBaseURL(string)` | Changes the base URL. Use it in tests. |

## API map

All methods take `ctx` as the first argument. Vehicle types are `fipe.Cars`, `fipe.Motorcycles` and `fipe.Trucks`.

| Method | Returns | REST path |
| --- | --- | --- |
| `References(ctx)` | `[]Reference` | `/references` |
| `Brands(ctx, vt)` | `[]Brand` | `/{vt}/brands` |
| `Models(ctx, vt, brand)` | `[]Model` | `/{vt}/brands/{brand}/models` |
| `Years(ctx, vt, brand, model)` | `[]Year` | `/{vt}/brands/{brand}/models/{model}/years` |
| `Vehicle(ctx, vt, brand, model, year)` | `*Vehicle` | `/{vt}/brands/{brand}/models/{model}/years/{year}` |
| `YearsByBrand(ctx, vt, brand)` | `[]Year` | `/{vt}/brands/{brand}/years` |
| `ModelsByBrandYear(ctx, vt, brand, year)` | `[]Model` | `/{vt}/brands/{brand}/years/{year}/models` |
| `YearsByFipeCode(ctx, vt, code)` | `[]Year` | `/{vt}/{code}/years` |
| `VehicleByFipeCode(ctx, vt, code, year)` | `*Vehicle` | `/{vt}/{code}/years/{year}` |
| `HistoryByFipeCode(ctx, vt, code, year)` | `*Vehicle` | `/{vt}/{code}/years/{year}/history` |

All methods except `References` accept `fipe.WithReference(code int)` as the last argument, to get the data of a past month.

The SDK has no method for license plates.

## Data rules

- **Codes are strings.** Brand, model and year codes are strings, for example `"59"`, `"5940"`, `"2014-3"`. The reference code is a string in `Reference.Code`, but `WithReference` takes an `int`. Use `strconv.Atoi`.
- **Year code.** The format is `<year>-<fuel>`. Read the fuel from `Year.Name` or `Vehicle.Fuel`. Do not decode the fuel number.
- **Zero KM.** `Vehicle.ModelYear == 32000` means a new vehicle. Show "Zero KM" to users, not `32000`.
- **Price is a string.** `Vehicle.Price` has the Brazilian format, for example `"R$ 17.322,00"`. To calculate, parse it to an integer number of cents. Do not use `float64` for money.
- **Reference codes are not in sequence.** Get the code of a month from `References`. Do not calculate a code from a date. The first item is the latest month.
- **History.** `HistoryByFipeCode` fills `Vehicle.PriceHistory`. `Vehicle.Price` and `Vehicle.ReferenceMonth` are empty in this response.
- **`Vehicle.VehicleType`** is a number (`1` for cars), not a `fipe.VehicleType`.

## Free tier and subscription

| Item | Without token | With token |
| --- | --- | --- |
| Reference months | The 3 latest months only | All months |
| `HistoryByFipeCode` | The 3 latest months only | Full history |
| Request limit | 500 requests in each period. The `x-ratelimit-reset` response header gives the seconds to the reset. | Higher limit |

A past month outside the free window returns status 402 for all endpoints.

## Errors

A status that is not 2xx returns `*fipe.APIError` with `StatusCode` and `Body`.

| Status | Match with | Action |
| --- | --- | --- |
| 404 | `errors.Is(err, fipe.ErrNotFound)` | The brand, model, year or FIPE code does not exist for that month. Do not retry. |
| 429 | `errors.Is(err, fipe.ErrTooManyRequests)` | Retry with backoff, or use a token. |
| 402 | `errors.As(err, &apiErr)` and `apiErr.StatusCode == http.StatusPaymentRequired` | The month or the history needs a subscription. Do not retry. Tell the user. |

## Performance

- FIPE prices change one time each month. Cache the responses. Use the reference code and the request path as the cache key.
- Brand and model lists are large and change slowly. Cache them for the whole reference month.
- Do not get the full chain (brands, models, years, price) for each request when you already have the FIPE code. Use `VehicleByFipeCode`.
