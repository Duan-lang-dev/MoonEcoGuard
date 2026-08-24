# MoonEcoGuard

MoonEcoGuard is a pure MoonBit toolkit for biodiversity survey data governance:
Darwin Core style occurrence records, CSV/TSV import, quality validation,
spatial checks, dataset statistics, GeoJSON/Markdown export, and sensitive species
coordinate protection.

> Coordinate protection can reduce public data leakage risk, but it cannot replace
> professional review or formal biodiversity data publishing governance.

## First MVP scope

- Import CSV/TSV occurrence tables with English or common Chinese field names.
- Normalize records into a Darwin Core inspired occurrence model.
- Validate required fields, coordinates, event links, dates, counts, duplicates,
  suspicious zero coordinates, precision and sensitive public coordinates.
- Check basic taxonomy field consistency and common local spelling hints.
- Protect sensitive taxa by decimal precision, grid centroid, deterministic jitter,
  region centroid, and sensitive free-text redaction.
- Export validation reports, dataset statistics, JSON-like text and GeoJSON.

## CLI examples

```powershell
moon run cmd/main -- validate examples/occurrence.csv
moon run cmd/main -- report examples/occurrence.csv --format markdown
moon run cmd/main -- protect examples/occurrence.csv --policy fixtures/sensitive-species.json
moon run cmd/main -- convert examples/occurrence.csv --format geojson
moon run cmd/main -- stats examples/occurrence.csv
moon run cmd/main -- geo-check examples/occurrence.csv --bounds 20,100,35,120
```

## Package map

- `darwincore`: Darwin Core inspired terms and occurrence/event/location models.
- `csv_reader`: small RFC-4180 style CSV/TSV reader for survey tables.
- `ecodata`: dataset import and Chinese/English field normalization.
- `validation`: data quality rules and report model.
- `geospatial`: coordinate ranges, haversine distance, grid centroids and bounds.
- `privacy`: sensitive species coordinate and text protection policies.
- `taxonomy`: local name-format and hierarchy checks.
- `formats`: Markdown, JSON and GeoJSON renderers.
- `statistics`: aggregate dataset metrics.
- `dwca` / `metadata`: first-pass Darwin Core Archive manifest/metadata models for the checked-in directory fixture; complete `.dwca.zip` processing is not yet claimed.

## Authorship

Created for the MoonBit hackathon by Duan-lang-dev <956327105@qq.com>.
