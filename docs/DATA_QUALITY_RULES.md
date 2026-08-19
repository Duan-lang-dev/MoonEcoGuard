# Data Quality Rules

MoonEcoGuard uses small, auditable rule codes so validation reports can be reviewed by ecologists, GIS analysts and data stewards.

## Error Rules

| Code | Field | Meaning | Default Severity |
|---|---|---|---|
| DWG-001 | decimalLatitude | Latitude is outside `-90..90`. | Error |
| DWG-002 | decimalLongitude | Longitude is outside `-180..180`. | Error |
| DWG-006 | occurrenceID | Required occurrence identifier is missing. | Error |
| DWG-007 | occurrenceID | Duplicate occurrence identifier in the same dataset. | Error |

## Warning Rules

| Code | Field | Meaning | Default Severity |
|---|---|---|---|
| DWG-003 | individualCount | Count is negative or implausibly high. | Warning |
| DWG-004 | eventID | Occurrence references an event that is not present. | Warning/Error depending on rules |
| DWG-005 | eventDate | Date does not look like ISO 8601. | Warning |
| DWG-101 | decimalLatitude/decimalLongitude | Sensitive taxon still has public coordinates. | Warning |
| DWG-108 | scientificName | Scientific name is empty. | Warning |
| DWG-109 | decimalLatitude/decimalLongitude | Coordinate is exactly `0,0`. | Warning |
| DWG-110 | decimalLatitude/decimalLongitude | Coordinate falls outside configured survey bounds. | Warning |
| DWG-111 | record fingerprint | Possible duplicate observation. | Warning |
| DWG-113 | decimalLatitude/decimalLongitude | Latitude and longitude may be reversed. | Warning |

## Review Principle

Validation output is intentionally conservative: MoonEcoGuard flags suspicious records for review, but it should not be treated as an authoritative taxonomic or publication decision system.
