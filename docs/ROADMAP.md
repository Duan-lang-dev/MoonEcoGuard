# MoonEcoGuard v0.1 roadmap

## Implemented in the initial scaffold

- CSV/TSV occurrence ingestion with Chinese and Darwin Core style aliases.
- Rule-based validation report with Darwin Core oriented diagnostic codes.
- Basic taxonomy hinting without claiming authoritative identification.
- Sensitive taxon coordinate protection by grid, precision, jitter, center, or removal.
- Markdown, JSON-like text, GeoJSON, and protected CSV output.
- CLI commands for validate/report/protect/convert/stats/geo-check/diff.

## Next milestones

1. Replace the minimal policy parser with typed JSON decoding.
2. Add real `.dwca.zip` extraction once a ZIP package/native stub is selected.
3. Parse `meta.xml` field mappings instead of relying on common aliases.
4. Add Event/MeasurementOrFact extension joins and archive writing.
5. Add GeoJSON polygon survey-area checks and browser map demo.
