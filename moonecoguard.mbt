///|
/// Public facade for common MoonEcoGuard workflows.
pub fn read_csv_string(source : String) -> @darwincore.Dataset {
  @ecodata.read_csv_string(source)
}

///|
pub fn validate(
  dataset : @darwincore.Dataset,
  rules? : @validation.ValidationRules = @validation.default_rules(),
) -> @validation.ValidationReport {
  @validation.validate(dataset, rules~)
}

///|
pub fn protect(
  dataset : @darwincore.Dataset,
  policy : @privacy.Policy,
) -> @darwincore.Dataset {
  @privacy.protect(dataset, policy)
}

///|
pub fn to_geojson(dataset : @darwincore.Dataset) -> String {
  @formats.to_geojson(dataset)
}

///|
pub fn validation_markdown(report : @validation.ValidationReport) -> String {
  @formats.validation_markdown(report)
}

///|
pub fn summarize(
  dataset : @darwincore.Dataset,
  sensitive_taxa? : Array[String] = [],
) -> @statistics.DatasetStats {
  @statistics.summarize(dataset, sensitive_taxa~)
}
