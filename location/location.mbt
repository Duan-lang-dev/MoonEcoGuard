///|
pub fn location_point(
  location_id : String,
  name : String,
  latitude : Double,
  longitude : Double,
) -> @darwincore.LocationRecord {
  {
    location_id,
    name,
    latitude: Some(latitude),
    longitude: Some(longitude),
    min_latitude: None,
    min_longitude: None,
    max_latitude: None,
    max_longitude: None,
  }
}

///|
pub fn in_bounds(
  location : @darwincore.LocationRecord,
  bounds : @geospatial.Bounds,
) -> Bool {
  match (location.latitude, location.longitude) {
    (Some(lat), Some(lon)) => bounds.contains(lat, lon)
    _ => false
  }
}
