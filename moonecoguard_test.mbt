///|
let sample_csv =
  #|记录编号,物种名称,观察时间,纬度,经度,观察者,联系方式,数量,地点,备注
  #|OBS-001,Cathaya argyrophylla,2026-05-12,26.123456,108.567890,观察员-001,observer001@example.org,3,武夷山样区 A,内部样点编号 A-01
  #|OBS-002,Ailuropoda melanoleuca,2026-05-13,31.482100,104.923100,观察员-002,13800000000,2,岷山样区,巡护路线附近
  #|OBS-003,,2026/05/14,0,0,,unknown@example.org,1,未知地点,

///|
test "CSV import maps Chinese headers to Darwin Core occurrence fields" {
  let dataset = @moonecoguard.read_csv_string(sample_csv)
  assert_eq(dataset.occurrences.length(), 3)
  assert_eq(dataset.occurrences[0].occurrence_id, "OBS-001")
  assert_eq(dataset.occurrences[1].scientific_name, "Ailuropoda melanoleuca")
  match dataset.occurrences[0].coordinate.latitude {
    Some(value) => assert_true(value > 26.12 && value < 26.13)
    None => fail("expected latitude")
  }
}

///|
test "validation catches date and zero coordinate issues" {
  let dataset = @moonecoguard.read_csv_string(sample_csv)
  let report = @validation.validate(dataset)
  assert_true(report.warning_count > 0)
  assert_true(report.error_count > 0)
  assert_true(@formats.validation_markdown(report).contains("DWG-005"))
}

///|
test "privacy grid protects sensitive coordinates and contact fields" {
  let dataset = @moonecoguard.read_csv_string(sample_csv)
  let policy = @privacy.grid_policy(
    ["Cathaya argyrophylla", "Ailuropoda melanoleuca"],
    5.0,
  )
  let public_dataset = @privacy.protect(dataset, policy)
  assert_true(public_dataset.occurrences[0].observer_contact is None)
  match public_dataset.occurrences[0].coordinate.uncertainty_meters {
    Some(value) => assert_eq(value, 5000.0)
    None => fail("expected coordinate uncertainty")
  }
  assert_true(
    public_dataset.occurrences[0].coordinate.latitude !=
    dataset.occurrences[0].coordinate.latitude,
  )
}

///|
test "GeoJSON export keeps georeferenced records" {
  let dataset = @moonecoguard.read_csv_string(sample_csv)
  let geojson = @moonecoguard.to_geojson(dataset)
  assert_true(geojson.contains("FeatureCollection"))
  assert_true(geojson.contains("OBS-001"))
}

///|
test "policy JSON extracts sensitive taxa" {
  let policy = @privacy.policy_from_json(
    (
      #|{"sensitive_taxa":["Cathaya argyrophylla","Ailuropoda melanoleuca"],"coordinate_policy":"grid","grid_size_km":5}
    ),
  )
  assert_eq(policy.sensitive_taxa.length(), 2)
  match policy.coordinate_mode {
    @privacy.CoordinateMode::Grid(size_km~) => assert_eq(size_km, 5.0)
    _ => fail("expected grid mode")
  }
  let dataset = @moonecoguard.read_csv_string(sample_csv)
  let stats = @statistics.summarize(
    dataset,
    sensitive_taxa=policy.sensitive_taxa,
  )
  assert_eq(stats.sensitive_record_count, 2)
}
