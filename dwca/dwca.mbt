///|
pub(all) enum CoreType {
  OccurrenceCore
  EventCore
  TaxonCore
  UnknownCore
} derive(Eq, Debug)

///|
pub(all) struct ArchiveFile {
  row_type : String
  location : String
  id_field : String
} derive(Eq, Debug)

///|
pub(all) struct ArchiveManifest {
  core : ArchiveFile?
  extensions : Array[ArchiveFile]
} derive(Eq, Debug)

///|
pub fn empty_manifest() -> ArchiveManifest {
  { core: None, extensions: [] }
}

///|
fn row_type_from_meta(meta_xml : String) -> String {
  if meta_xml.contains("Occurrence") {
    "http://rs.tdwg.org/dwc/terms/Occurrence"
  } else if meta_xml.contains("Event") {
    "http://rs.tdwg.org/dwc/terms/Event"
  } else if meta_xml.contains("Taxon") {
    "http://rs.tdwg.org/dwc/terms/Taxon"
  } else {
    "unknown"
  }
}

///|
/// First-pass meta.xml recognizer. ZIP extraction will be layered on this manifest model.
pub fn parse_meta_xml(meta_xml : String) -> ArchiveManifest {
  let core = if meta_xml.contains("<core") {
    Some({
      row_type: row_type_from_meta(meta_xml),
      location: "occurrence.txt",
      id_field: "id",
    })
  } else {
    None
  }
  { core, extensions: [] }
}

///|
pub fn core_type(row_type : String) -> CoreType {
  if row_type.contains("Occurrence") {
    OccurrenceCore
  } else if row_type.contains("Event") {
    EventCore
  } else if row_type.contains("Taxon") {
    TaxonCore
  } else {
    UnknownCore
  }
}

///|
pub fn relate_by_event(
  dataset : @darwincore.Dataset,
) -> Map[String, Array[@darwincore.OccurrenceRecord]] {
  let groups : Map[String, Array[@darwincore.OccurrenceRecord]] = Map([])
  for record in dataset.occurrences {
    match record.event_id {
      Some(event_id) =>
        match groups.get(event_id) {
          Some(existing) => existing.push(record)
          None => groups[event_id] = [record]
        }
      None => ()
    }
  }
  groups
}
