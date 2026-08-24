# Demo Script

This script shows the recommended MoonEcoGuard walkthrough for hackathon judging.

## 1. Validate a clean sample

```powershell
moon run cmd/main -- validate examples/occurrence.csv
```

Expected result: a compact validation report with records, valid count, warnings and errors.

## 2. Validate a deliberately dirty sample

```powershell
moon run cmd/main -- validate examples/occurrence-errors.csv --policy fixtures/sensitive-species.json
```

Expected findings include duplicate IDs, non-ISO dates, `0,0` coordinates, out-of-range coordinates, sensitive taxa with public coordinates and a possible latitude/longitude swap.

## 3. Run GIS bounds checks

```powershell
moon run cmd/main -- geo-check examples/occurrence-errors.csv --bounds 20,100,35,120
```

The configured rectangle approximates a southern China survey window and helps surface coordinates outside the target region.

## 4. Protect sensitive species coordinates

```powershell
moon run cmd/main -- protect examples/occurrence.csv --policy fixtures/sensitive-species.json --output public-occurrence.csv
```

Expected result: sensitive taxa are exported with protected coordinates and redacted contact fields.

## 5. Export map-ready GeoJSON

```powershell
moon run cmd/main -- convert public-occurrence.csv --format geojson
```

The output can be copied into QGIS, geojson.io or a browser map prototype.

## 6. Compare private and public files

```powershell
moon run cmd/main -- diff examples/occurrence.csv public-occurrence.csv
```

Expected result: the comparison matches records by `occurrenceID` and reports matched, added, removed, coordinate, contact and remarks changes. It does not compare rows by array position.

Invalid input examples should fail visibly instead of silently falling back:

```powershell
moon run cmd/main -- geo-check examples/occurrence-errors.csv --bounds invalid
moon run cmd/main -- protect examples/occurrence.csv --policy missing-policy.json
```

Expected messages include `Invalid bounds` and `Unable to read policy file`.

## 7. Check a directory-style DwCA fixture

```powershell
moon run cmd/main -- dwca-check fixtures/dwca
moon run cmd/main -- dwca-convert fixtures/dwca --format csv
```

Expected result: `meta.xml` declares an Occurrence core at `occurrence.txt`; the tool reports the mapped field count and converts the two synthetic records to the normalized occurrence CSV format. This is a constrained directory fixture workflow, not complete `.dwca.zip` support.
