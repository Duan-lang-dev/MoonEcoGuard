///|
pub(all) struct Bounds {
  min_latitude : Double
  min_longitude : Double
  max_latitude : Double
  max_longitude : Double
} derive(Eq, Debug)

///|
pub fn valid_latitude(latitude : Double) -> Bool {
  latitude >= -90.0 && latitude <= 90.0
}

///|
pub fn valid_longitude(longitude : Double) -> Bool {
  longitude >= -180.0 && longitude <= 180.0
}

///|
pub fn valid_coordinate(latitude : Double, longitude : Double) -> Bool {
  valid_latitude(latitude) && valid_longitude(longitude)
}

///|
pub fn maybe_reversed(latitude : Double, longitude : Double) -> Bool {
  !valid_latitude(latitude) &&
  latitude >= -180.0 &&
  latitude <= 180.0 &&
  longitude >= -90.0 &&
  longitude <= 90.0
}

///|
pub fn Bounds::contains(
  self : Bounds,
  latitude : Double,
  longitude : Double,
) -> Bool {
  latitude >= self.min_latitude &&
  latitude <= self.max_latitude &&
  longitude >= self.min_longitude &&
  longitude <= self.max_longitude
}

///|
fn deg_to_rad(value : Double) -> Double {
  value / 180.0 * @math.PI
}

///|
/// Haversine distance in kilometers.
pub fn distance_km(
  lat1 : Double,
  lon1 : Double,
  lat2 : Double,
  lon2 : Double,
) -> Double {
  let dlat = deg_to_rad(lat2 - lat1)
  let dlon = deg_to_rad(lon2 - lon1)
  let a = @math.sin(dlat / 2.0) * @math.sin(dlat / 2.0) +
    @math.cos(deg_to_rad(lat1)) *
    @math.cos(deg_to_rad(lat2)) *
    @math.sin(dlon / 2.0) *
    @math.sin(dlon / 2.0)
  6371.0088 * 2.0 * @math.asin(a.sqrt())
}

///|
/// Approximate a grid-cell center. Longitude step is adjusted by latitude.
pub fn grid_center(
  latitude : Double,
  longitude : Double,
  size_km : Double,
) -> (Double, Double) {
  let safe_size = if size_km <= 0.0 { 1.0 } else { size_km }
  let lat_step = safe_size / 111.32
  let cos_lat = @math.cos(deg_to_rad(latitude)).abs()
  let lon_km = if cos_lat < 0.01 { 111.32 } else { 111.32 * cos_lat }
  let lon_step = safe_size / lon_km
  let lat_cell = (latitude / lat_step).floor()
  let lon_cell = (longitude / lon_step).floor()
  (lat_cell * lat_step + lat_step / 2.0, lon_cell * lon_step + lon_step / 2.0)
}

///|
pub fn round_to_decimals(value : Double, decimals : Int) -> Double {
  let mut factor = 1.0
  let mut i = 0
  while i < decimals {
    factor = factor * 10.0
    i = i + 1
  }
  (value * factor).round() / factor
}

///|
fn pseudo_unit(seed : String) -> Double {
  let mut hash = 2166136261U
  seed
  .iter()
  .each(ch => {
    hash = hash ^ ch.to_uint()
    hash = hash * 16777619U
  })
  (hash % 1000000U).reinterpret_as_int().to_double() / 1000000.0
}

///|
/// Deterministic jitter for reproducible public datasets.
pub fn jitter(
  latitude : Double,
  longitude : Double,
  radius_km : Double,
  seed : String,
) -> (Double, Double) {
  let radius = if radius_km <= 0.0 { 1.0 } else { radius_km }
  let u = pseudo_unit(seed + ":u")
  let v = pseudo_unit(seed + ":v")
  let bearing = 2.0 * @math.PI * u
  let distance = radius * v.sqrt()
  let lat_delta = @math.cos(bearing) * distance / 111.32
  let cos_lat = @math.cos(deg_to_rad(latitude)).abs()
  let lon_scale = if cos_lat < 0.01 { 111.32 } else { 111.32 * cos_lat }
  let lon_delta = @math.sin(bearing) * distance / lon_scale
  (latitude + lat_delta, longitude + lon_delta)
}

///|
pub fn coordinate_precision_decimals(text : String) -> Int {
  let normalized = text.trim().to_owned()
  let parts = normalized.split(".").to_array()
  if parts.length() == 2 {
    parts[1].trim().length()
  } else {
    0
  }
}
