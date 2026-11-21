---
type: regex
pattern: 'float(32|64)'
match: not_contains
target:
  source: file
  path: history.go
---
