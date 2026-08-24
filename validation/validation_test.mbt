///|
fn has_code(report : @validation.ValidationReport, code : String) -> Bool {
  for issue in report.diagnostics {
    if issue.code == code {
      return true
    }
  }
  false
}

///|
test "validation acceptance rules" {
  let invalid = @darwincore.occurrence(
    "DUP-001",
    "Cathaya argyrophylla",
    latitude=95.0,
    longitude=181.0,
    event_date="2026/05/12",
    individual_count=-1,
  )
  let duplicate = @darwincore.occurrence(
    "DUP-001",
    "Cathaya argyrophylla",
    latitude=26.0,
    longitude=108.0,
    event_date="2026-05-12",
  )
  let zero = @darwincore.occurrence(
    "ZERO-001",
    "Cathaya argyrophylla",
    latitude=0.0,
    longitude=0.0,
    event_date="2026-05-12",
  )
  let outside = @darwincore.occurrence(
    "BOUND-001",
    "Cathaya argyrophylla",
    latitude=40.0,
    longitude=108.0,
    event_date="2026-05-12",
  )
  let missing_name = @darwincore.occurrence(
    "NAME-001",
    "",
    latitude=26.0,
    longitude=108.0,
    event_date="2026-05-12",
  )
  let high_count = @darwincore.occurrence(
    "COUNT-001",
    "Cathaya argyrophylla",
    latitude=26.0,
    longitude=108.0,
    event_date="2026-05-12",
    individual_count=10001,
  )
  let dataset : @darwincore.Dataset = {
    occurrences: [
      invalid, duplicate, duplicate, zero, outside, missing_name, high_count,
    ],
    events: [],
    locations: [],
    measurements: [],
  }
  let report = @validation.validate(dataset, rules={
    required_occurrence_id: true,
    required_scientific_name: true,
    require_event_ids_to_exist: false,
    sensitive_taxa: ["cathaya argyrophylla"],
    max_individual_count: 10000,
    coordinate_bounds: Some({
      min_latitude: 20.0,
      min_longitude: 100.0,
      max_latitude: 35.0,
      max_longitude: 120.0,
    }),
  })
  assert_true(has_code(report, "DWG-001"))
  assert_true(has_code(report, "DWG-002"))
  assert_true(has_code(report, "DWG-003"))
  assert_true(has_code(report, "DWG-005"))
  assert_true(has_code(report, "DWG-007"))
  assert_true(has_code(report, "DWG-101"))
  assert_true(has_code(report, "DWG-108"))
  assert_true(has_code(report, "DWG-109"))
  assert_true(has_code(report, "DWG-110"))
  assert_true(has_code(report, "DWG-111"))
}

///|
test "validation keeps valid occurrence clean" {
  let record = @darwincore.occurrence(
    "OK-001",
    "Cathaya argyrophylla",
    latitude=26.0,
    longitude=108.0,
    event_date="2026-05-12",
    individual_count=3,
  )
  assert_true(@validation.validate_occurrence(record).is_empty())
}
