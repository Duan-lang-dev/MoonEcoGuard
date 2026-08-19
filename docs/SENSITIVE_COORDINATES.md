# Sensitive Coordinate Protection

MoonEcoGuard supports publication-oriented coordinate protection for endangered, rare or collection-risk species.

## Supported Modes

| Mode | Purpose | Public Output |
|---|---|---|
| Decimal reduction | Lower coordinate precision for lightweight sharing. | Fewer decimal places |
| Grid | Snap coordinates to a configurable kilometer grid. | Grid-cell representative point |
| Jitter | Move coordinates within a bounded radius. | Deterministically perturbed point |
| Center | Replace exact sample points with region or protected-area center points. | Area center coordinate |
| Redaction | Remove direct identifiers from selected fields. | Empty contact / sensitive note fields |

## Fields Commonly Redacted

- `observer_contact`
- phone numbers and email addresses in notes
- cave names, patrol routes and internal plot identifiers
- `verbatimCoordinates`
- private sampling-point labels

## Default Demonstration Policy

The fixture policy protects `Cathaya argyrophylla`, `Ailuropoda melanoleuca` and other high-risk taxa with a 5 km grid policy. The CLI accepts the policy with `--policy fixtures/sensitive-species.json`.

## Important Limitation

Coordinate protection can only reduce the risk of public data leakage. It cannot replace expert review, institutional approval, legal compliance checks or a formal biodiversity data publishing process.
