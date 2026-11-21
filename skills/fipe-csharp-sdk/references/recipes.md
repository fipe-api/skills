# FIPE C# SDK recipes

This code was tested with `Fipe.Api.Br` 0.1.0 against the live API, and with xUnit.

## Contents

- [Parse a price](#parse-a-price)
- [Find a vehicle by name](#find-a-vehicle-by-name)
- [Get a past month](#get-a-past-month)
- [Handle a subscription error](#handle-a-subscription-error)
- [Retry when rate limited](#retry-when-rate-limited)
- [Test with a stub handler](#test-with-a-stub-handler)

## Parse a price

```csharp
public static class FipePrice
{
    public static decimal ParseBrl(string price)
    {
        var digits = new string(price.Where(char.IsDigit).ToArray());
        if (digits.Length == 0)
        {
            throw new FormatException($"Price has no digits: '{price}'");
        }
        return decimal.Parse(digits) / 100m;
    }
}
```

`FipePrice.ParseBrl("R$ 17.322,00")` returns `17322.00m`.

## Find a vehicle by name

Model names are long, for example `Gol Trendline 1.0 T.Flex 12V 5p`. Match all words of the query, without case. If more than one model matches, let the user select one. Do not select the first match without asking.

```csharp
public static class FipeLookup
{
    public const int ZeroKmYear = 32000;

    public static bool IsZeroKm(this Vehicle vehicle) => vehicle.ModelYear == ZeroKmYear;

    public static Brand? FindBrand(IEnumerable<Brand> brands, string name) =>
        brands.FirstOrDefault(b => b.Name.Contains(name, StringComparison.OrdinalIgnoreCase));

    public static IReadOnlyList<Model> FindModels(IEnumerable<Model> models, string query)
    {
        var words = query.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        return models.Where(m => ContainsAll(m.Name, words)).ToList();
    }

    public static Year? FindYear(IEnumerable<Year> years, int modelYear) =>
        years.FirstOrDefault(y => y.Code.StartsWith($"{modelYear}-", StringComparison.Ordinal));

    private static bool ContainsAll(string name, IEnumerable<string> words) =>
        words.All(w => name.Contains(w, StringComparison.OrdinalIgnoreCase));
}
```

`string.Contains(string, StringComparison)` needs .NET Core 2.1 or later. On .NET Framework, use `name.IndexOf(word, StringComparison.OrdinalIgnoreCase) >= 0`.

Brand names use FIPE spelling, for example `GM - Chevrolet` and `VW - VolksWagen`. `FindBrand(brands, "volkswagen")` finds `VW - VolksWagen`.

A model can have more than one fuel for the same year. `FindYear` returns the first one. When the fuel is important, match `Year.Name` too.

## Get a past month

```csharp
public static int? ReferenceCode(IEnumerable<Reference> references, string month)
{
    var match = references.FirstOrDefault(r => string.Equals(r.Month, month, StringComparison.OrdinalIgnoreCase));
    return match is null ? null : int.Parse(match.Code);
}
```

`Reference.Month` has the format `novembro/2025`.

```csharp
var references = await client.GetReferencesAsync(ct);
var reference = FipeLookup.ReferenceCode(references, "setembro/2026")
    ?? throw new ArgumentException("Unknown reference month");
var vehicle = await client.GetVehicleByFipeCodeAsync(VehicleType.Cars, "004278-1", "2006-1", reference: reference, cancellationToken: ct);
```

## Handle a subscription error

`FipeApiException` has no property for 402.

```csharp
public static bool IsPaymentRequired(this FipeApiException ex) =>
    ex.StatusCode == HttpStatusCode.PaymentRequired;
```

```csharp
try
{
    return await client.GetVehicleByFipeCodeAsync(VehicleType.Cars, code, year, reference: reference, cancellationToken: ct);
}
catch (FipeApiException ex) when (ex.IsPaymentRequired())
{
    throw new SubscriptionRequiredException(ex);
}
catch (FipeApiException ex) when (ex.IsNotFound)
{
    return null;
}
```

## Retry when rate limited

Retry only on 429. Do not retry 402 or 404.

```csharp
public static async Task<T> WithRetryAsync<T>(Func<Task<T>> call, int attempts = 3, CancellationToken cancellationToken = default)
{
    var delay = TimeSpan.FromSeconds(1);
    for (var attempt = 1; ; attempt++)
    {
        try
        {
            return await call().ConfigureAwait(false);
        }
        catch (FipeApiException ex) when (ex.IsRateLimited && attempt < attempts)
        {
            await Task.Delay(delay, cancellationToken).ConfigureAwait(false);
            delay += delay;
        }
    }
}
```

```csharp
var vehicle = await FipeLookup.WithRetryAsync(
    () => client.GetVehicleByFipeCodeAsync(VehicleType.Cars, "004278-1", "2006-1", cancellationToken: ct),
    cancellationToken: ct);
```

If the project uses Polly or `Microsoft.Extensions.Http.Resilience`, add a retry policy for status 429 on the named `HttpClient` instead.

## Test with a stub handler

The path in the stub does not include `/api/v2`, because `baseUrl` replaces the full base URL.

```csharp
public sealed class StubHandler : HttpMessageHandler
{
    private readonly Func<HttpRequestMessage, HttpResponseMessage> _respond;

    public StubHandler(Func<HttpRequestMessage, HttpResponseMessage> respond) => _respond = respond;

    protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken) =>
        Task.FromResult(_respond(request));
}

public class PriceTests
{
    private static HttpResponseMessage Json(string body) =>
        new(HttpStatusCode.OK) { Content = new StringContent(body, Encoding.UTF8, "application/json") };

    [Fact]
    public async Task GetsPriceByFipeCode()
    {
        var handler = new StubHandler(req => req.RequestUri!.AbsolutePath == "/cars/004278-1/years/2006-1"
            ? Json("""{"codeFipe":"004278-1","modelYear":2006,"price":"R$ 17.322,00"}""")
            : new HttpResponseMessage(HttpStatusCode.NotFound));
        var client = new FipeClient(new HttpClient(handler), baseUrl: "https://fipe.test");

        var vehicle = await client.GetVehicleByFipeCodeAsync(VehicleType.Cars, "004278-1", "2006-1");

        Assert.Equal(17322.00m, FipePrice.ParseBrl(vehicle.Price));
    }

    [Fact]
    public async Task MapsPaymentRequired()
    {
        var handler = new StubHandler(_ => new HttpResponseMessage(HttpStatusCode.PaymentRequired));
        var client = new FipeClient(new HttpClient(handler), baseUrl: "https://fipe.test");

        var ex = await Assert.ThrowsAsync<FipeApiException>(() => client.GetBrandsAsync(VehicleType.Cars, reference: 327));

        Assert.True(ex.IsPaymentRequired());
    }
}
```

Raw string literals (`"""..."""`) need C# 11. For older versions, escape the quotes.
