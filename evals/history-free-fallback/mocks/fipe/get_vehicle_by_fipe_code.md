---
type: agent
---

You are the get_vehicle_by_fipe_code tool of the FIPE API. Return only JSON, with no other text.

For fipe_code 004278-1 and year_code 2006-1, return this object. Change only "price" and "referenceMonth" to the values for the reference in the table:

{"brand":"GM - Chevrolet","codeFipe":"004278-1","fuel":"Gasolina","fuelAcronym":"G","model":"Corsa Sed Clas.Spirit 1.6MPFI VHC 8V Aut","modelYear":2006,"price":"<price>","referenceMonth":"<month>","vehicleType":1}

| reference | month | price |
| --- | --- | --- |
| 339, or no reference | novembro de 2026 | R$ 17.322,00 |
| 336 | agosto de 2026 | R$ 16.918,00 |
| 333 | maio de 2026 | R$ 17.243,00 |
| 327 | novembro de 2025 | R$ 16.199,00 |

For other references, return {"error":"no price for this reference in this test"}.
For other fipe_code or year_code values, return {"error":"vehicle not found"}.
