///|
fn sample_record() -> @darwincore.OccurrenceRecord {
  let record = @darwincore.occurrence(
    "PRIV-001",
    "Cathaya argyrophylla",
    latitude=26.123456,
    longitude=108.56789,
    event_date="2026-05-12",
  )
  {
    ..record,
    observer_contact: Some("observer@example.org"),
    remarks: Some("洞穴路线附近的样点"),
    coordinate: { ..record.coordinate, verbatim: Some("26.123456,108.567890") },
  }
}

///|
test "protection summary audits deterministic grid transformation" {
  let dataset : @darwincore.Dataset = {
    occurrences: [sample_record()],
    events: [],
    locations: [],
    measurements: [],
  }
  let policy = @privacy.grid_policy(["Cathaya argyrophylla"], 5.0)
  let first = @privacy.protect_with_summary(dataset, policy)
  let second = @privacy.protect_with_summary(dataset, policy)
  assert_eq(first.summary.record_count, 1)
  assert_eq(first.summary.sensitive_record_count, 1)
  assert_eq(first.summary.coordinate_changed_count, 1)
  assert_eq(first.summary.coordinate_removed_count, 0)
  assert_eq(first.summary.observer_contact_removed_count, 1)
  assert_eq(first.summary.remarks_redacted_count, 1)
  assert_eq(first.dataset, second.dataset)
  assert_true(first.dataset.occurrences[0].observer_contact is None)
  assert_true(first.dataset.occurrences[0].coordinate.verbatim is None)
}

///|
test "dataset diff matches records by occurrence ID" {
  let private_first = @darwincore.occurrence(
    "ID-001",
    "Cathaya argyrophylla",
    latitude=26.0,
    longitude=108.0,
  )
  let private_second = @darwincore.occurrence(
    "ID-002",
    "Ailuropoda melanoleuca",
    latitude=31.0,
    longitude=104.0,
  )
  let public_second = @darwincore.occurrence(
    "ID-002",
    "Ailuropoda melanoleuca",
    latitude=31.0,
    longitude=104.0,
  )
  let public_third = @darwincore.occurrence(
    "ID-003",
    "Prionailurus bengalensis",
    latitude=26.2,
    longitude=108.6,
  )
  let private_dataset : @darwincore.Dataset = {
    occurrences: [private_first, private_second],
    events: [],
    locations: [],
    measurements: [],
  }
  let public_dataset : @darwincore.Dataset = {
    occurrences: [public_second, public_third],
    events: [],
    locations: [],
    measurements: [],
  }
  let result = @privacy.diff(private_dataset, public_dataset)
  assert_eq(result.private_record_count, 2)
  assert_eq(result.public_record_count, 2)
  assert_eq(result.matched_count, 1)
  assert_eq(result.removed_count, 1)
  assert_eq(result.added_count, 1)
  assert_eq(result.coordinate_changed_count, 0)
  assert_eq(result.coordinate_removed_count, 0)
}

///|
test "remove coordinates reports removals" {
  let dataset : @darwincore.Dataset = {
    occurrences: [sample_record()],
    events: [],
    locations: [],
    measurements: [],
  }
  let policy : @privacy.Policy = {
    sensitive_taxa: ["Cathaya argyrophylla"],
    coordinate_mode: @privacy.CoordinateMode::RemoveCoordinates,
    remove_observer_contact: false,
    remove_verbatim_coordinates: true,
    redact_private_remarks: false,
  }
  let result = @privacy.protect_with_summary(dataset, policy)
  assert_eq(result.summary.coordinate_changed_count, 1)
  assert_eq(result.summary.coordinate_removed_count, 1)
  assert_eq(result.summary.observer_contact_removed_count, 0)
  assert_eq(result.summary.remarks_redacted_count, 0)
  assert_true(result.dataset.occurrences[0].coordinate.has_decimal() == false)
}
