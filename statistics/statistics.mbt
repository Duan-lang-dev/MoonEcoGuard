///|
pub(all) struct DatasetStats {
  record_count : Int
  unique_taxa : Int
  georeferenced_count : Int
  zero_zero_count : Int
  missing_scientific_name_count : Int
  sensitive_record_count : Int
} derive(Eq, Debug)

///|
fn is_sensitive(
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
pub fn summarize(
  dataset : @darwincore.Dataset,
  sensitive_taxa? : Array[String] = [],
) -> DatasetStats {
  let taxa : Map[String, Unit] = Map([])
  let mut geo = 0
  let mut zero = 0
  let mut missing = 0
  let mut sensitive = 0
  for record in dataset.occurrences {
    let key = record.taxon_key()
    if !key.is_empty() {
      taxa[key] = ()
    }
    if record.has_public_coordinates() {
      geo = geo + 1
    }
    if record.coordinate.is_zero_zero() {
      zero = zero + 1
    }
    if record.scientific_name.trim().is_empty() {
      missing = missing + 1
    }
    if is_sensitive(sensitive_taxa, record) {
      sensitive = sensitive + 1
    }
  }
  {
    record_count: dataset.occurrences.length(),
    unique_taxa: taxa.length(),
    georeferenced_count: geo,
    zero_zero_count: zero,
    missing_scientific_name_count: missing,
    sensitive_record_count: sensitive,
  }
}
