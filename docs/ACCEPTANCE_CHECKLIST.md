# MoonEcoGuard Acceptance Checklist

## Build and package checks

- [x] `moon check`
- [x] `moon test`
- [x] `moon fmt --check`
- [x] `moon info`
- [x] CI runs `moon version --all`
- [x] CI runs warning-denied check and test

## CLI workflows

- [x] `validate examples/occurrence.csv`
- [x] `validate examples/occurrence-errors.csv --policy fixtures/sensitive-species.json`
- [x] `report examples/occurrence.csv --format markdown`
- [x] `protect examples/occurrence.csv --policy fixtures/sensitive-species.json`
- [x] `convert examples/occurrence.csv --format geojson`
- [x] `stats examples/occurrence.csv`
- [x] `geo-check examples/occurrence-errors.csv --bounds 20,100,35,120`
- [x] `diff examples/occurrence.csv examples/occurrence.csv` matches by `occurrenceID`
- [x] Invalid bounds produce an explicit error
- [x] Missing policy files produce an explicit error
- [x] `dwca-check fixtures/dwca`
- [x] `dwca-convert fixtures/dwca --format csv`

## Core capabilities

- [x] Darwin Core inspired occurrence model
- [x] CSV and TSV field normalization
- [x] Auditable coordinate, date, count, identifier and taxonomy checks
- [x] Sensitive coordinate protection with deterministic grid and jitter modes
- [x] Protection summary without exposing original sensitive values
- [x] Observer contact, verbatim coordinate and sensitive remarks redaction
- [x] Dataset statistics
- [x] GeoJSON export using `[longitude, latitude]`
- [x] Markdown validation reports
- [x] Directory fixture containing first-pass DwCA manifest models

## Scope boundary

The current release does not claim complete `.dwca.zip` reading or writing, full EML parsing, arbitrary Darwin Core extension joins, or authoritative taxonomy identification. The `dwca` package currently provides first-pass manifest/metadata models; complete archive processing remains future work.

## Release review

- [ ] Review all public API changes with `moon info`
- [ ] Verify fixtures contain no real sensitive observations or personal contact data
- [ ] Verify `fs_compat` host requirements for the target runtime
- [ ] Verify the package from a clean consumer project before publishing
- [ ] Decide whether generated `pkg.generated.mbti` files are tracked consistently
