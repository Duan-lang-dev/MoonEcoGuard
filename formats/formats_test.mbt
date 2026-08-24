///|
test "format exports preserve escaping and coordinate order" {
  let record = @darwincore.occurrence(
    "FMT-001",
    "Species \"quoted\"",
    latitude=26.12,
    longitude=108.57,
    event_date="2026-05-12",
  )
  let dataset : @darwincore.Dataset = {
    occurrences: [
      { ..record, remarks: Some("line 1\nline 2") },
      @darwincore.occurrence(
        "FMT-002",
        "No coordinates",
        event_date="2026-05-13",
      ),
    ],
    events: [],
    locations: [],
    measurements: [],
  }
  let csv = @formats.occurrences_csv(dataset)
  assert_true(csv.contains("FMT-001"))
  assert_true(csv.contains("Species \"\"quoted\"\""))
  assert_true(csv.contains("line 1 line 2"))
  let json = @formats.to_json(dataset)
  assert_true(json.contains("Species \\\"quoted\\\""))
  let geojson = @formats.to_geojson(dataset)
  assert_true(geojson.contains("[108.57,26.12]"))
  assert_true(geojson.contains("FMT-001"))
  assert_true(!geojson.contains("FMT-002"))
}

///|
test "markdown report has stable metric headings" {
  let report : @validation.ValidationReport = {
    record_count: 1,
    valid_count: 1,
    warning_count: 0,
    error_count: 0,
    diagnostics: [],
  }
  let markdown = @formats.validation_markdown(report)
  assert_true(markdown.contains("# MoonEcoGuard validation report"))
  assert_true(markdown.contains("| Records | 1 |"))
  assert_true(markdown.contains("No diagnostics."))
}
