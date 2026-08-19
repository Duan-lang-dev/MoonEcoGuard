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

Expected result: a summary of how many record coordinates changed during protection.
