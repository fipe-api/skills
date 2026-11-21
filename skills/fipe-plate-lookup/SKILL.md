---
name: fipe-plate-lookup
description: Find the vehicle data and the FIPE price of a Brazilian vehicle from its license plate (placa). Use when the user gives a plate in the old format (ABC1234) or the Mercosul format (ABC1D23), or asks "qual o valor FIPE desta placa".
---

# FIPE plate lookup

## Tool

Use `get_vehicle_by_plate` of the `fipe` MCP server. This tool needs a subscription token.

## Procedure

1. Normalize the plate: remove spaces and hyphens, and use upper case. For example, `abc-1d23` becomes `ABC1D23`.
2. Make sure that the plate has one of these formats:
   - Old format: 3 letters and 4 digits (`ABC1234`).
   - Mercosul format: 3 letters, 1 digit, 1 letter, 2 digits (`ABC1D23`).
3. If the plate is not correct, tell the user and ask for the correct plate. Do not call the tool.
4. Call `get_vehicle_by_plate`.
5. If the result has more than one FIPE price, show all of them. One plate can match more than one FIPE version.

## Errors

- If the tool tells that a token is necessary or that the token is not valid, tell the user that plate lookup needs a FIPE API subscription. Then offer a lookup by brand, model and year with the `fipe-price-lookup` skill.
- If the tool does not find the plate, tell the user. Do not guess a vehicle.

## Privacy

A license plate can identify a person. Do not keep plates in files or logs. Do not send a plate to a service other than the `fipe` MCP server.

## Output

Show the brand, model, model year, fuel, FIPE code, price and reference month for each FIPE match.
