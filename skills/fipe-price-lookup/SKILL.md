---
name: fipe-price-lookup
description: Find the FIPE price of a Brazilian car, motorcycle or truck from its brand, model and year, or from its FIPE code. Use when the user asks "how much is a <vehicle> worth", "tabela FIPE", "preço FIPE", "valor FIPE", or gives a FIPE code such as 004278-1.
---

# FIPE price lookup

The FIPE table is the reference for used vehicle prices in Brazil. It changes each month.

## Tools

Use the tools of the `fipe` MCP server.

| Tool | Use |
| --- | --- |
| `list_brands` | Get the brand codes for a vehicle type. |
| `list_models` | Get the model codes of a brand. |
| `list_model_years` | Get the year codes of a model. |
| `get_vehicle` | Get the price from brand, model and year codes. |
| `list_years_by_fipe_code` | Get the year codes for a FIPE code. |
| `get_vehicle_by_fipe_code` | Get the price from a FIPE code and a year code. |

## Procedure

1. Find the vehicle type: `cars`, `motorcycles` or `trucks`. Pickups and SUVs are `cars`. If you are not sure, ask the user.
2. If the user gives a FIPE code (format `NNNNNN-N`), go to step 7.
3. Call `list_brands`. Match the brand name without case. Brands have FIPE names, for example "GM - Chevrolet" for Chevrolet and "VW - VolksWagen" for Volkswagen.
4. Call `list_models`. A brand can have hundreds of models. Filter the list by the words that the user gave (model name, engine size, version, transmission).
5. If more than one model matches, show the user a short list (maximum 10 items) and ask which one. Do not select a version for the user.
6. Call `list_model_years`, then `get_vehicle`. Stop here.
7. Call `list_years_by_fipe_code`, then `get_vehicle_by_fipe_code`.

## Year codes

- A year code has the format `<year>-<fuel>`, for example `2014-3`.
- The year `32000` means a new vehicle ("Zero KM"). Show it as "Zero KM", not as a year.
- Read the fuel from the `name` field of the year item. Do not guess the fuel from the number.
- If the user does not give the fuel and the model has more than one fuel for that year, ask the user.

## Reference month

- If you do not give `reference`, the tools use the latest month.
- For a past month, call `list_references` and use the `code` of that month. Codes are not in a sequence: do not calculate a code from a month.

## Output

Show this data from the result:

- Brand and model
- Model year (or "Zero KM") and fuel
- FIPE code
- Price, as the tool gives it (for example `R$ 17.322,00`)
- Reference month

Tell the user that the FIPE price is an average market reference. It is not the sale price of a specified vehicle.
