---
name: fipe-price-history
description: Show how the FIPE price of a Brazilian vehicle changed over time, and calculate its depreciation or appreciation. Use when the user asks for the price history, the price in a past month, "quanto desvalorizou", or a chart of FIPE prices.
---

# FIPE price history

## Tools

Use the tools of the `fipe` MCP server.

| Tool | Use |
| --- | --- |
| `get_price_history` | Get all the monthly prices in one call. Needs a paid subscription token. |
| `list_references` | Get the reference month codes. The first item is the latest month. |
| `get_vehicle_by_fipe_code` | Get the price for one reference month. |

## Procedure

1. Get the FIPE code and the year code of the vehicle. If you do not have them, use the `fipe-price-lookup` skill first.
2. Call `get_price_history`.
3. If step 2 fails because there is no token, use the free procedure:
   1. Call `list_references`.
   2. Select the months to show. Do not get more than 12 months unless the user asks. For a long period, use one month for each year or each quarter.
   3. For each month, call `get_vehicle_by_fipe_code` with the `reference` code of that month. These calls are independent: send them in parallel.
   4. If a month has no price for that vehicle, the vehicle was not in the table in that month. Skip that month and tell the user.

## Calculation

- Prices are strings in Brazilian format (`R$ 17.322,00`). To calculate, remove `R$` and the dots, then change the comma to a point.
- Change = latest price minus first price.
- Change percentage = change divided by first price, times 100. Use one decimal place.
- Show money values in Brazilian format.

## Output

1. A table with the columns: month, price, change from the previous row.
2. A summary: first price, latest price, total change and change percentage.
3. If a chart tool is available, show a line chart of price by month.

Tell the user that inflation is not included in the calculation.
