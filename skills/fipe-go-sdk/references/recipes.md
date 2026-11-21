# FIPE Go SDK recipes

This code was tested with `github.com/fipe-api/go-sdk` v0.1.0 against the live API.

## Contents

- [Parse a price](#parse-a-price)
- [Find a vehicle by name](#find-a-vehicle-by-name)
- [Get a past month](#get-a-past-month)
- [Handle a subscription error](#handle-a-subscription-error)
- [Retry when rate limited](#retry-when-rate-limited)
- [Test with a fake server](#test-with-a-fake-server)

## Parse a price

Keep money as an integer number of cents.

```go
func ParseBRL(price string) (int64, error) {
	digits := strings.Map(keepDigit, price)
	if digits == "" {
		return 0, fmt.Errorf("parse price %q: no digits", price)
	}
	return strconv.ParseInt(digits, 10, 64)
}

func keepDigit(r rune) rune {
	if unicode.IsDigit(r) {
		return r
	}
	return -1
}
```

`ParseBRL("R$ 17.322,00")` returns `1732200`.

## Find a vehicle by name

Model names are long, for example `Gol Trendline 1.0 T.Flex 12V 5p`. Match all words of the query, without case. If more than one model matches, let the user select one. Do not select the first match without asking.

```go
const zeroKMYear = 32000

func IsZeroKM(v *fipe.Vehicle) bool {
	return v.ModelYear == zeroKMYear
}

func containsFold(s, substr string) bool {
	return strings.Contains(strings.ToLower(s), strings.ToLower(substr))
}

func matchAllWords(name string, words []string) bool {
	for _, w := range words {
		if !containsFold(name, w) {
			return false
		}
	}
	return true
}

func FindBrand(brands []fipe.Brand, name string) (fipe.Brand, bool) {
	for _, b := range brands {
		if containsFold(b.Name, name) {
			return b, true
		}
	}
	return fipe.Brand{}, false
}

func FindModels(models []fipe.Model, query string) []fipe.Model {
	words := strings.Fields(query)
	var found []fipe.Model
	for _, m := range models {
		if matchAllWords(m.Name, words) {
			found = append(found, m)
		}
	}
	return found
}

func FindYear(years []fipe.Year, modelYear int) (fipe.Year, bool) {
	prefix := strconv.Itoa(modelYear) + "-"
	for _, y := range years {
		if strings.HasPrefix(y.Code, prefix) {
			return y, true
		}
	}
	return fipe.Year{}, false
}
```

Brand names use FIPE spelling, for example `GM - Chevrolet` and `VW - VolksWagen`. `FindBrand(brands, "volkswagen")` finds `VW - VolksWagen`.

A model can have more than one fuel for the same year. `FindYear` returns the first one. When the fuel is important, match `Year.Name` too.

## Get a past month

```go
func ReferenceCode(refs []fipe.Reference, month string) (int, bool) {
	for _, r := range refs {
		if strings.EqualFold(r.Month, month) {
			code, err := strconv.Atoi(r.Code)
			return code, err == nil
		}
	}
	return 0, false
}
```

`Reference.Month` has the format `novembro/2025`.

```go
refs, err := client.References(ctx)
if err != nil {
	return err
}
code, ok := ReferenceCode(refs, "setembro/2026")
if !ok {
	return fmt.Errorf("unknown reference month")
}
v, err := client.VehicleByFipeCode(ctx, fipe.Cars, "004278-1", "2006-1", fipe.WithReference(code))
```

## Handle a subscription error

The SDK has no sentinel error for 402.

```go
func IsPaymentRequired(err error) bool {
	var apiErr *fipe.APIError
	return errors.As(err, &apiErr) && apiErr.StatusCode == http.StatusPaymentRequired
}
```

```go
v, err := client.VehicleByFipeCode(ctx, fipe.Cars, code, year, fipe.WithReference(ref))
switch {
case IsPaymentRequired(err):
	return ErrSubscriptionRequired
case errors.Is(err, fipe.ErrNotFound):
	return ErrVehicleNotFound
case err != nil:
	return err
}
```

## Retry when rate limited

Retry only on 429. Do not retry 402 or 404.

```go
func WithRetry[T any](ctx context.Context, attempts int, call func() (T, error)) (T, error) {
	var zero T
	delay := time.Second
	for i := 1; ; i++ {
		result, err := call()
		retryable := errors.Is(err, fipe.ErrTooManyRequests) && i < attempts
		if !retryable {
			return result, err
		}
		select {
		case <-ctx.Done():
			return zero, ctx.Err()
		case <-time.After(delay):
		}
		delay *= 2
	}
}
```

```go
v, err := WithRetry(ctx, 3, func() (*fipe.Vehicle, error) {
	return client.VehicleByFipeCode(ctx, fipe.Cars, "004278-1", "2006-1")
})
```

## Test with a fake server

The path in the fake server does not include `/api/v2`, because `WithBaseURL` replaces the full base URL.

```go
func TestVehicleByFipeCode(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/cars/004278-1/years/2006-1" {
			http.NotFound(w, r)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"codeFipe":"004278-1","modelYear":2006,"price":"R$ 17.322,00"}`))
	}))
	defer srv.Close()

	client := fipe.New(fipe.WithBaseURL(srv.URL))

	v, err := client.VehicleByFipeCode(context.Background(), fipe.Cars, "004278-1", "2006-1")
	if err != nil {
		t.Fatal(err)
	}
	cents, err := ParseBRL(v.Price)
	if err != nil {
		t.Fatal(err)
	}
	if cents != 1732200 {
		t.Fatalf("got %d cents, want 1732200", cents)
	}
}
```
