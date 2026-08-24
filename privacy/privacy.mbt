///|
pub(all) enum CoordinateMode {
  RoundDecimals(decimals~ : Int)
  Grid(size_km~ : Double)
  Jitter(radius_km~ : Double)
  RegionCenter(latitude~ : Double, longitude~ : Double)
  RemoveCoordinates
} derive(Eq, Debug)

///|
pub(all) struct Policy {
  sensitive_taxa : Array[String]
  coordinate_mode : CoordinateMode
  remove_observer_contact : Bool
  remove_verbatim_coordinates : Bool
  redact_private_remarks : Bool
} derive(Eq, Debug)

///|
pub fn default_policy() -> Policy {
  {
    sensitive_taxa: [],
    coordinate_mode: Grid(size_km=5.0),
    remove_observer_contact: true,
    remove_verbatim_coordinates: true,
    redact_private_remarks: true,
  }
}

///|
pub fn grid_policy(taxa : Array[String], size_km : Double) -> Policy {
  {
    sensitive_taxa: taxa,
    coordinate_mode: Grid(size_km~),
    remove_observer_contact: true,
    remove_verbatim_coordinates: true,
    redact_private_remarks: true,
  }
}

///|
fn sensitive_taxon(
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
fn protected_coordinate(
  record : @darwincore.OccurrenceRecord,
  mode : CoordinateMode,
) -> @darwincore.Coordinate {
  match (record.coordinate.latitude, record.coordinate.longitude) {
    (Some(lat), Some(lon)) =>
      match mode {
        RoundDecimals(decimals~) =>
          {
            latitude: Some(@geospatial.round_to_decimals(lat, decimals)),
            longitude: Some(@geospatial.round_to_decimals(lon, decimals)),
            uncertainty_meters: record.coordinate.uncertainty_meters,
            verbatim: None,
          }
        Grid(size_km~) => {
          let (new_lat, new_lon) = @geospatial.grid_center(lat, lon, size_km)
          {
            latitude: Some(new_lat),
            longitude: Some(new_lon),
            uncertainty_meters: Some(size_km * 1000.0),
            verbatim: None,
          }
        }
        Jitter(radius_km~) => {
          let (new_lat, new_lon) = @geospatial.jitter(
            lat,
            lon,
            radius_km,
            record.occurrence_id,
          )
          {
            latitude: Some(new_lat),
            longitude: Some(new_lon),
            uncertainty_meters: Some(radius_km * 1000.0),
            verbatim: None,
          }
        }
        RegionCenter(latitude~, longitude~) =>
          {
            latitude: Some(latitude),
            longitude: Some(longitude),
            uncertainty_meters: record.coordinate.uncertainty_meters,
            verbatim: None,
          }
        RemoveCoordinates =>
          {
            latitude: None,
            longitude: None,
            uncertainty_meters: None,
            verbatim: None,
          }
      }
    _ => record.coordinate
  }
}

///|
fn protect_remarks(remarks : String?) -> String? {
  match remarks {
    Some(text) if text.contains("洞") ||
      text.contains("路线") ||
      text.contains("样点") => Some("[REDACTED sensitive field note]")
    other => other
  }
}

///|
fn rebuild_record(
  record : @darwincore.OccurrenceRecord,
  coordinate : @darwincore.Coordinate,
  observer_contact : String?,
  remarks : String?,
) -> @darwincore.OccurrenceRecord {
  {
    occurrence_id: record.occurrence_id,
    event_id: record.event_id,
    scientific_name: record.scientific_name,
    vernacular_name: record.vernacular_name,
    kingdom: record.kingdom,
    phylum: record.phylum,
    class_name: record.class_name,
    order_name: record.order_name,
    family: record.family,
    genus: record.genus,
    specific_epithet: record.specific_epithet,
    taxon_rank: record.taxon_rank,
    event_date: record.event_date,
    individual_count: record.individual_count,
    coordinate,
    locality: record.locality,
    observer: record.observer,
    observer_contact,
    basis_of_record: record.basis_of_record,
    occurrence_status: record.occurrence_status,
    remarks,
  }
}

///|
pub fn protect_occurrence(
  record : @darwincore.OccurrenceRecord,
  policy : Policy,
) -> @darwincore.OccurrenceRecord {
  let is_sensitive = sensitive_taxon(policy.sensitive_taxa, record)
  let coord = if is_sensitive {
    protected_coordinate(record, policy.coordinate_mode)
  } else if policy.remove_verbatim_coordinates {
    {
      latitude: record.coordinate.latitude,
      longitude: record.coordinate.longitude,
      uncertainty_meters: record.coordinate.uncertainty_meters,
      verbatim: None,
    }
  } else {
    record.coordinate
  }
  let contact = if policy.remove_observer_contact {
    None
  } else {
    record.observer_contact
  }
  let remarks = if policy.redact_private_remarks {
    protect_remarks(record.remarks)
  } else {
    record.remarks
  }
  rebuild_record(record, coord, contact, remarks)
}

///|
pub(all) struct ProtectionSummary {
  record_count : Int
  sensitive_record_count : Int
  coordinate_changed_count : Int
  coordinate_removed_count : Int
  observer_contact_removed_count : Int
  remarks_redacted_count : Int
} derive(Eq, Debug)

///|
pub(all) struct ProtectionResult {
  dataset : @darwincore.Dataset
  summary : ProtectionSummary
} derive(Eq, Debug)

///|
pub fn protect_with_summary(
  dataset : @darwincore.Dataset,
  policy : Policy,
) -> ProtectionResult {
  let occurrences : Array[@darwincore.OccurrenceRecord] = []
  let mut sensitive_record_count = 0
  let mut coordinate_changed_count = 0
  let mut coordinate_removed_count = 0
  let mut observer_contact_removed_count = 0
  let mut remarks_redacted_count = 0
  for record in dataset.occurrences {
    let protected_record = protect_occurrence(record, policy)
    if sensitive_taxon(policy.sensitive_taxa, record) {
      sensitive_record_count = sensitive_record_count + 1
    }
    if record.coordinate != protected_record.coordinate {
      coordinate_changed_count = coordinate_changed_count + 1
    }
    if record.coordinate.has_decimal() &&
      !protected_record.coordinate.has_decimal() {
      coordinate_removed_count = coordinate_removed_count + 1
    }
    if record.observer_contact is Some(_) &&
      protected_record.observer_contact is None {
      observer_contact_removed_count = observer_contact_removed_count + 1
    }
    if record.remarks != protected_record.remarks {
      remarks_redacted_count = remarks_redacted_count + 1
    }
    occurrences.push(protected_record)
  }
  {
    dataset: {
      occurrences,
      events: dataset.events,
      locations: dataset.locations,
      measurements: dataset.measurements,
    },
    summary: {
      record_count: dataset.occurrences.length(),
      sensitive_record_count,
      coordinate_changed_count,
      coordinate_removed_count,
      observer_contact_removed_count,
      remarks_redacted_count,
    },
  }
}

///|
pub(all) struct DatasetDiff {
  private_record_count : Int
  public_record_count : Int
  matched_count : Int
  added_count : Int
  removed_count : Int
  coordinate_changed_count : Int
  coordinate_removed_count : Int
  observer_contact_changed_count : Int
  remarks_changed_count : Int
} derive(Eq, Debug)

///|
pub fn diff(
  private_dataset : @darwincore.Dataset,
  public_dataset : @darwincore.Dataset,
) -> DatasetDiff {
  let private_ids : Map[String, Unit] = Map([])
  let public_records : Map[String, @darwincore.OccurrenceRecord] = Map([])
  for record in private_dataset.occurrences {
    private_ids[record.occurrence_id] = ()
  }
  for record in public_dataset.occurrences {
    public_records[record.occurrence_id] = record
  }
  let mut matched_count = 0
  let mut removed_count = 0
  let mut coordinate_changed_count = 0
  let mut coordinate_removed_count = 0
  let mut observer_contact_changed_count = 0
  let mut remarks_changed_count = 0
  for private_record in private_dataset.occurrences {
    match public_records.get(private_record.occurrence_id) {
      None => removed_count = removed_count + 1
      Some(public_record) => {
        matched_count = matched_count + 1
        if private_record.coordinate != public_record.coordinate {
          coordinate_changed_count = coordinate_changed_count + 1
        }
        if private_record.coordinate.has_decimal() &&
          !public_record.coordinate.has_decimal() {
          coordinate_removed_count = coordinate_removed_count + 1
        }
        if private_record.observer_contact != public_record.observer_contact {
          observer_contact_changed_count = observer_contact_changed_count + 1
        }
        if private_record.remarks != public_record.remarks {
          remarks_changed_count = remarks_changed_count + 1
        }
      }
    }
  }
  let mut added_count = 0
  for public_record in public_dataset.occurrences {
    if !private_ids.contains(public_record.occurrence_id) {
      added_count = added_count + 1
    }
  }
  {
    private_record_count: private_dataset.occurrences.length(),
    public_record_count: public_dataset.occurrences.length(),
    matched_count,
    added_count,
    removed_count,
    coordinate_changed_count,
    coordinate_removed_count,
    observer_contact_changed_count,
    remarks_changed_count,
  }
}

///|
pub fn protect(
  dataset : @darwincore.Dataset,
  policy : Policy,
) -> @darwincore.Dataset {
  protect_with_summary(dataset, policy).dataset
}

///|
fn parse_number_after(
  source : String,
  key : String,
  default : Double,
) -> Double {
  let parts = source.split(key).to_array()
  if parts.length() < 2 {
    return default
  }
  let tail = parts[1].split(":").to_array()
  if tail.length() < 2 {
    return default
  }
  let mut number = ""
  let mut started = false
  let mut active = true
  tail[1]
  .iter()
  .each(ch => {
    if active && ((ch >= '0' && ch <= '9') || ch == '.' || ch == '-') {
      number = number + "\{ch}"
      started = true
    } else if started {
      active = false
    }
  })
  let mut sign = 1.0
  let mut value = 0.0
  let mut factor = 0.1
  let mut after_dot = false
  let mut valid = false
  let mut index = 0
  number
  .iter()
  .each(ch => {
    if index == 0 && ch == '-' {
      sign = -1.0
    } else if ch == '.' {
      after_dot = true
    } else if ch >= '0' && ch <= '9' {
      valid = true
      let digit = (ch.to_int() - '0'.to_int()).to_double()
      if after_dot {
        value = value + digit * factor
        factor = factor / 10.0
      } else {
        value = value * 10.0 + digit
      }
    }
    index = index + 1
  })
  if valid {
    value * sign
  } else {
    default
  }
}

///|
fn quoted_values_near(source : String, key : String) -> Array[String] {
  let values : Array[String] = []
  let parts = source.split(key).to_array()
  if parts.length() < 2 {
    return values
  }
  let array_parts = parts[1].split("[").to_array()
  if array_parts.length() < 2 {
    return values
  }
  let body = array_parts[1].split("]").to_array()[0]
  let chunks = body.split("\"").to_array()
  let mut index = 1
  while index < chunks.length() {
    let text = chunks[index].trim().to_owned()
    if !text.is_empty() && text != key {
      values.push(text)
    }
    index = index + 2
  }
  values
}

///|
/// Minimal policy JSON reader for the documented sample config.
pub fn policy_from_json(source : String) -> Policy {
  let taxa = quoted_values_near(source, "sensitive_taxa")
  let size = parse_number_after(source, "grid_size_km", 5.0)
  let lower = source.to_lower()
  let mode = if lower.contains("\"coordinate_policy\": \"round\"") ||
    lower.contains("\"coordinate_mode\": \"round\"") {
    RoundDecimals(decimals=parse_number_after(source, "decimals", 2.0).to_int())
  } else if lower.contains("\"coordinate_policy\": \"jitter\"") ||
    lower.contains("\"coordinate_mode\": \"jitter\"") {
    Jitter(radius_km=parse_number_after(source, "radius_km", 5.0))
  } else if lower.contains("\"coordinate_policy\": \"remove\"") ||
    lower.contains("\"coordinate_mode\": \"remove\"") {
    RemoveCoordinates
  } else {
    Grid(size_km=size)
  }
  {
    sensitive_taxa: taxa,
    coordinate_mode: mode,
    remove_observer_contact: !source.contains(
      "\"remove_observer_contact\": false",
    ),
    remove_verbatim_coordinates: true,
    redact_private_remarks: true,
  }
}
