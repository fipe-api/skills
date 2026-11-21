---
name: fipe-compare
description: Compare the FIPE prices of two or more Brazilian vehicles, versions or model years. Use when the user asks "which is cheaper", "compare X and Y in the FIPE table", or wants to see the price of one model across years.
---

# FIPE compare

## Procedure

1. Make a list of the vehicles to compare. For each vehicle, get the vehicle type, brand, model, year and fuel.
2. Find each vehicle with the `fipe-price-lookup` skill. Do the lookups in parallel when they are independent.
3. Use the same reference month for all vehicles. If the user gives no month, use the latest month for all of them.
4. If one vehicle is not in the table for that month or year, tell the user. Compare the other vehicles.

## Compare one model across years

1. Call `list_model_years` (or `list_years_by_fipe_code`) one time.
2. Call `get_vehicle` (or `get_vehicle_by_fipe_code`) for each year that the user asks for. If the user gives no years, use the 5 latest years.

## Output

1. A table with the columns: vehicle, model year, fuel, FIPE code, price.
2. Sort the table by price, from low to high.
3. Below the table, show the price difference between the lowest and the highest price, in money and in percentage.

Use the same reference month for all rows, and show that month above the table.
