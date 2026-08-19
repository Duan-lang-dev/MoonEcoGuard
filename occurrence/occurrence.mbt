///|
pub fn new_occurrence(
  occurrence_id : String,
  scientific_name : String,
  latitude? : Double,
  longitude? : Double,
) -> @darwincore.OccurrenceRecord {
  match (latitude, longitude) {
    (Some(lat), Some(lon)) =>
      @darwincore.occurrence(
        occurrence_id,
        scientific_name,
        latitude=lat,
        longitude=lon,
      )
    (Some(lat), None) =>
      @darwincore.occurrence(occurrence_id, scientific_name, latitude=lat)
    (None, Some(lon)) =>
      @darwincore.occurrence(occurrence_id, scientific_name, longitude=lon)
    (None, None) => @darwincore.occurrence(occurrence_id, scientific_name)
  }
}
