///|
/// Darwin Core inspired geographic coordinate container.
pub(all) struct Coordinate {
  latitude : Double?
  longitude : Double?
  uncertainty_meters : Double?
  verbatim : String?
} derive(Eq, Debug)

///|
pub fn Coordinate::has_decimal(self : Coordinate) -> Bool {
  self.latitude is Some(_) && self.longitude is Some(_)
}

///|
pub fn Coordinate::is_zero_zero(self : Coordinate) -> Bool {
  match (self.latitude, self.longitude) {
    (Some(lat), Some(lon)) => lat == 0.0 && lon == 0.0
    _ => false
  }
}

///|
/// Darwin Core style occurrence row normalized from field-survey tables.
pub(all) struct OccurrenceRecord {
  occurrence_id : String
  event_id : String?
  scientific_name : String
  vernacular_name : String?
  kingdom : String?
  phylum : String?
  class_name : String?
  order_name : String?
  family : String?
  genus : String?
  specific_epithet : String?
  taxon_rank : String?
  event_date : String?
  individual_count : Int?
  coordinate : Coordinate
  locality : String?
  observer : String?
  observer_contact : String?
  basis_of_record : String?
  occurrence_status : String?
  remarks : String?
} derive(Eq, Debug)

///|
pub fn OccurrenceRecord::display_name(self : OccurrenceRecord) -> String {
  if !self.scientific_name.trim().is_empty() {
    self.scientific_name
  } else {
    match self.vernacular_name {
      Some(name) if !name.trim().is_empty() => name
      _ => "<unnamed taxon>"
    }
  }
}

///|
pub fn OccurrenceRecord::taxon_key(self : OccurrenceRecord) -> String {
  let sci = self.scientific_name.trim().to_owned().to_lower()
  if !sci.is_empty() {
    sci
  } else {
    match self.vernacular_name {
      Some(name) => name.trim().to_owned().to_lower()
      None => ""
    }
  }
}

///|
pub fn OccurrenceRecord::has_public_coordinates(
  self : OccurrenceRecord,
) -> Bool {
  self.coordinate.has_decimal()
}

///|
pub(all) struct SamplingEvent {
  event_id : String
  parent_event_id : String?
  event_date : String?
  end_date : String?
  locality : String?
  sampling_protocol : String?
  sample_size_value : Double?
  sample_size_unit : String?
} derive(Eq, Debug)

///|
pub(all) struct LocationRecord {
  location_id : String
  name : String
  latitude : Double?
  longitude : Double?
  min_latitude : Double?
  min_longitude : Double?
  max_latitude : Double?
  max_longitude : Double?
} derive(Eq, Debug)

///|
pub(all) struct MeasurementOrFact {
  measurement_id : String
  occurrence_id : String?
  event_id : String?
  measurement_type : String
  measurement_value : String
  measurement_unit : String?
} derive(Eq, Debug)

///|
pub(all) struct Dataset {
  occurrences : Array[OccurrenceRecord]
  events : Array[SamplingEvent]
  locations : Array[LocationRecord]
  measurements : Array[MeasurementOrFact]
} derive(Eq, Debug)

///|
pub fn empty_dataset() -> Dataset {
  { occurrences: [], events: [], locations: [], measurements: [] }
}

///|
pub fn Dataset::occurrence_count(self : Dataset) -> Int {
  self.occurrences.length()
}

///|
pub fn Dataset::event_ids(self : Dataset) -> Map[String, Unit] {
  let ids : Map[String, Unit] = Map([])
  for event in self.events {
    if !event.event_id.trim().is_empty() {
      ids[event.event_id] = ()
    }
  }
  ids
}

///|
pub fn Dataset::has_event_id(self : Dataset, event_id : String) -> Bool {
  self.event_ids().contains(event_id)
}

///|
pub fn occurrence(
  occurrence_id : String,
  scientific_name : String,
  latitude? : Double,
  longitude? : Double,
  event_date? : String,
  event_id? : String,
  vernacular_name? : String,
  individual_count? : Int,
) -> OccurrenceRecord {
  {
    occurrence_id,
    event_id,
    scientific_name,
    vernacular_name,
    kingdom: None,
    phylum: None,
    class_name: None,
    order_name: None,
    family: None,
    genus: None,
    specific_epithet: None,
    taxon_rank: None,
    event_date,
    individual_count,
    coordinate: {
      latitude,
      longitude,
      uncertainty_meters: None,
      verbatim: None,
    },
    locality: None,
    observer: None,
    observer_contact: None,
    basis_of_record: Some("HumanObservation"),
    occurrence_status: Some("present"),
    remarks: None,
  }
}
