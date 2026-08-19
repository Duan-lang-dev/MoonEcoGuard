///|
pub(all) enum Severity {
  Info
  Warning
  Error
} derive(Eq, Debug)

///|
pub(all) struct Diagnostic {
  code : String
  severity : Severity
  occurrence_id : String?
  field : String?
  message : String
  suggestion : String?
} derive(Eq, Debug)

///|
pub(all) struct ValidationRules {
  required_occurrence_id : Bool
  required_scientific_name : Bool
  require_event_ids_to_exist : Bool
  sensitive_taxa : Array[String]
  max_individual_count : Int
  coordinate_bounds : @geospatial.Bounds?
} derive(Eq, Debug)

///|
pub(all) struct ValidationReport {
  record_count : Int
  valid_count : Int
  warning_count : Int
  error_count : Int
  diagnostics : Array[Diagnostic]
} derive(Eq, Debug)

///|
pub fn default_rules() -> ValidationRules {
  {
    required_occurrence_id: true,
    required_scientific_name: true,
    require_event_ids_to_exist: false,
    sensitive_taxa: [],
    max_individual_count: 10000,
    coordinate_bounds: None,
  }
}

///|
fn diagnostic(
  code : String,
  severity : Severity,
  occurrence_id : String?,
  field : String?,
  message : String,
  suggestion? : String,
) -> Diagnostic {
  { code, severity, occurrence_id, field, message, suggestion }
}

///|
fn contains_taxon(
  taxa : Array[String],
  record : @darwincore.OccurrenceRecord,
) -> Bool {
  let key = record.taxon_key()
  for taxon in taxa {
    if key == taxon.trim().to_owned().to_lower() {
      return true
    }
  }
  false
}

///|
fn looks_iso8601_date(text : String) -> Bool {
  let trimmed = text.trim()
  if trimmed.length() < 10 {
    return false
  }
  let parts = trimmed.split("-").to_array()
  parts.length() >= 3 &&
  parts[0].length() == 4 &&
  parts[1].length() == 2 &&
  parts[2].length() >= 2
}

///|
fn opt_string(value : String?) -> String {
  match value {
    Some(text) => text.trim().to_owned()
    None => ""
  }
}

///|
fn opt_double_string(value : Double?) -> String {
  match value {
    Some(number) => number.to_string()
    None => ""
  }
}

///|
fn duplicate_key(record : @darwincore.OccurrenceRecord) -> String {
  record.taxon_key() +
  "|" +
  opt_string(record.event_date) +
  "|" +
  opt_double_string(record.coordinate.latitude) +
  "|" +
  opt_double_string(record.coordinate.longitude)
}

///|
pub fn validate_occurrence(
  record : @darwincore.OccurrenceRecord,
  rules? : ValidationRules = default_rules(),
) -> Array[Diagnostic] {
  let issues : Array[Diagnostic] = []
  let record_id = if record.occurrence_id.trim().is_empty() {
    None
  } else {
    Some(record.occurrence_id)
  }
  if rules.required_occurrence_id && record.occurrence_id.trim().is_empty() {
    issues.push(
      diagnostic(
        "DWG-006",
        Error,
        None,
        Some("occurrenceID"),
        "occurrenceID is required",
      ),
    )
  }
  if rules.required_scientific_name && record.scientific_name.trim().is_empty() {
    issues.push(
      diagnostic(
        "DWG-108",
        Warning,
        record_id,
        Some("scientificName"),
        "scientificName is empty",
      ),
    )
  }
  match record.coordinate.latitude {
    Some(latitude) if !@geospatial.valid_latitude(latitude) =>
      issues.push(
        diagnostic(
          "DWG-001",
          Error,
          record_id,
          Some("decimalLatitude"),
          "latitude out of range",
          suggestion="Expected -90..90",
        ),
      )
    _ => ()
  }
  match record.coordinate.longitude {
    Some(longitude) if !@geospatial.valid_longitude(longitude) =>
      issues.push(
        diagnostic(
          "DWG-002",
          Error,
          record_id,
          Some("decimalLongitude"),
          "longitude out of range",
          suggestion="Expected -180..180",
        ),
      )
    _ => ()
  }
  match (record.coordinate.latitude, record.coordinate.longitude) {
    (Some(latitude), Some(longitude)) if @geospatial.maybe_reversed(
        latitude, longitude,
      ) =>
      issues.push(
        diagnostic(
          "DWG-113",
          Warning,
          record_id,
          Some("decimalLatitude/decimalLongitude"),
          "possible latitude/longitude reversal",
          suggestion="Swap latitude and longitude after manual review",
        ),
      )
    (Some(0.0), Some(0.0)) =>
      issues.push(
        diagnostic(
          "DWG-109",
          Warning,
          record_id,
          Some("decimalLatitude/decimalLongitude"),
          "coordinate is exactly 0,0",
        ),
      )
    (Some(latitude), Some(longitude)) =>
      match rules.coordinate_bounds {
        Some(bounds) if !bounds.contains(latitude, longitude) =>
          issues.push(
            diagnostic(
              "DWG-110",
              Warning,
              record_id,
              Some("decimalLatitude/decimalLongitude"),
              "coordinate falls outside configured survey bounds",
            ),
          )
        _ => ()
      }
    _ => ()
  }
  match record.individual_count {
    Some(count) if count < 0 =>
      issues.push(
        diagnostic(
          "DWG-003",
          Error,
          record_id,
          Some("individualCount"),
          "individualCount must not be negative",
        ),
      )
    Some(count) if count > rules.max_individual_count =>
      issues.push(
        diagnostic(
          "DWG-111",
          Warning,
          record_id,
          Some("individualCount"),
          "individualCount is unusually high",
        ),
      )
    _ => ()
  }
  match record.event_date {
    Some(date) if !looks_iso8601_date(date) =>
      issues.push(
        diagnostic(
          "DWG-005",
          Error,
          record_id,
          Some("eventDate"),
          "eventDate should use ISO 8601 date format",
        ),
      )
    _ => ()
  }
  if contains_taxon(rules.sensitive_taxa, record) &&
    record.has_public_coordinates() {
    issues.push(
      diagnostic(
        "DWG-101",
        Warning,
        record_id,
        Some("decimalLatitude/decimalLongitude"),
        "sensitive species has public coordinates",
      ),
    )
  }
  for
    issue in @taxonomy.scientific_name_issues(
      record.scientific_name,
      record.genus,
    ) {
    issues.push({
      code: issue.code,
      severity: Warning,
      occurrence_id: record_id,
      field: Some("scientificName"),
      message: issue.message,
      suggestion: issue.suggestion,
    })
  }
  issues
}

///|
pub fn validate(
  dataset : @darwincore.Dataset,
  rules? : ValidationRules = default_rules(),
) -> ValidationReport {
  let diagnostics : Array[Diagnostic] = []
  let seen_ids : Map[String, Int] = Map([])
  let seen_duplicates : Map[String, Unit] = Map([])
  let event_ids = dataset.event_ids()
  let mut invalid_rows = 0
  let mut zero_zero = 0
  for record in dataset.occurrences {
    let before = diagnostics.length()
    if !record.occurrence_id.trim().is_empty() {
      match seen_ids.get(record.occurrence_id) {
        Some(_) =>
          diagnostics.push(
            diagnostic(
              "DWG-007",
              Error,
              Some(record.occurrence_id),
              Some("occurrenceID"),
              "duplicate occurrenceID",
            ),
          )
        None => seen_ids[record.occurrence_id] = 1
      }
    }
    if rules.require_event_ids_to_exist {
      match record.event_id {
        Some(event_id) if !event_ids.contains(event_id) =>
          diagnostics.push(
            diagnostic(
              "DWG-004",
              Error,
              Some(record.occurrence_id),
              Some("eventID"),
              "eventID does not exist",
            ),
          )
        _ => ()
      }
    }
    if record.coordinate.is_zero_zero() {
      zero_zero = zero_zero + 1
    }
    let key = duplicate_key(record)
    if !key.has_prefix("|") {
      if seen_duplicates.contains(key) {
        diagnostics.push(
          diagnostic(
            "DWG-114",
            Warning,
            Some(record.occurrence_id),
            None,
            "possible duplicate observation",
          ),
        )
      } else {
        seen_duplicates[key] = ()
      }
    }
    for item in validate_occurrence(record, rules~) {
      diagnostics.push(item)
    }
    let mut has_error = false
    let mut i = before
    while i < diagnostics.length() {
      if diagnostics[i].severity == Error {
        has_error = true
      }
      i = i + 1
    }
    if has_error {
      invalid_rows = invalid_rows + 1
    }
  }
  if dataset.occurrences.length() > 0 &&
    zero_zero * 4 >= dataset.occurrences.length() {
    diagnostics.push(
      diagnostic(
        "DWG-115",
        Warning,
        None,
        Some("decimalLatitude/decimalLongitude"),
        "many records are concentrated at 0,0",
      ),
    )
  }
  let mut warnings = 0
  let mut errors = 0
  for issue in diagnostics {
    match issue.severity {
      Error => errors = errors + 1
      Warning => warnings = warnings + 1
      Info => ()
    }
  }
  {
    record_count: dataset.occurrences.length(),
    valid_count: dataset.occurrences.length() - invalid_rows,
    warning_count: warnings,
    error_count: errors,
    diagnostics,
  }
}

///|
pub fn ValidationReport::is_valid(self : ValidationReport) -> Bool {
  self.error_count == 0
}
