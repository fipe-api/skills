---
expect:
  vehicle_type: cars
  fipe_code: ["004278-1", "005556-5"]
  year_code: ["2005-1", "2006-1", "2026-5", "32000-5"]
---

{{file:fixtures/fipe-vehicles/{input.fipe_code}_{input.year_code}.json}}
