---
expect:
  vehicle_type: cars
  model_code: ["7522", "11469"]
  year_code: ["2017-5", "2018-5", "2026-5", "32000-5"]
---

{{file:fixtures/vehicles/{input.model_code}_{input.year_code}.json}}
