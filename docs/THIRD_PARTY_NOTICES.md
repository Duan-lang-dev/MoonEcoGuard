# Third-Party Notices

## Project implementation

MoonEcoGuard application and library code in this repository is an original MoonBit implementation released under the Apache License 2.0. The project author is Duan-lang-dev.

## Standards and terminology

Darwin Core terms and the Darwin Core Archive layout are used as interoperability references. This project is not affiliated with or an official implementation of Darwin Core, GBIF, or the TDWG standards community.

The `dwca` package currently contains first-pass manifest and metadata models. It does not claim complete `.dwca.zip` processing or complete EML semantics.

## Example data

The CSV, TSV, JSON policy and Darwin Core fixture files in this repository are synthetic demonstration data. They are not intended to represent real sensitive species observations or real personal contact information.

## Runtime integration

The `fs_compat` package uses MoonBit host file-system imports for the CLI runtime. Its portability depends on the host providing the corresponding `__moonbit_fs_unstable` imports; this dependency should not be treated as a general cross-backend file-system guarantee.

## License

See the repository `LICENSE` file for the full Apache License 2.0 text.
