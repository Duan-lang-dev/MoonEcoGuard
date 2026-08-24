///|
pub(all) enum CoreType {
  OccurrenceCore
  EventCore
  TaxonCore
  UnknownCore
} derive(Eq, Debug)

///|
pub(all) struct ArchiveField {
  term : String
  index : Int
} derive(Eq, Debug)

///|
pub(all) struct ArchiveFile {
  row_type : String
  location : String
  id_field : String
  fields : Array[ArchiveField]
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
fn attribute_value(source : String, name : String) -> String? {
  let marker = name + "=\""
  let parts = source.split(marker).to_array()
  if parts.length() < 2 {
    return None
  }
  Some(parts[1].split("\"").to_array()[0].to_owned())
}

///|
fn element_text(source : String, name : String) -> String? {
  let parts = source.split("<" + name + ">").to_array()
  if parts.length() < 2 {
    return None
  }
  Some(parts[1].split("</" + name + ">").to_array()[0].trim().to_owned())
}

///|
fn term_name(term : String) -> String {
  let parts = term.split("/terms/").to_array()
  if parts.length() >= 2 {
    parts[parts.length() - 1].to_owned()
  } else {
    term
  }
}

///|
fn parse_int_local(text : String) -> Int? {
  let trimmed = text.trim()
  if trimmed.is_empty() {
    return None
  }
  let mut value = 0
  let mut valid = true
  for ch in trimmed {
    if ch >= '0' && ch <= '9' {
      value = value * 10 + (ch.to_int() - '0'.to_int())
    } else {
      valid = false
    }
  }
  if valid {
    Some(value)
  } else {
    None
  }
}

///|
fn parse_fields(core_xml : String) -> Array[ArchiveField] {
  let fields : Array[ArchiveField] = []
  for part in core_xml.split("<field") {
    let fragment = part.to_owned()
    match
      (attribute_value(fragment, "index"), attribute_value(fragment, "term")) {
      (Some(index_text), Some(term)) =>
        match parse_int_local(index_text) {
          Some(index) => fields.push({ term: term_name(term), index })
          None => ()
        }
      _ => ()
    }
  }
  fields
}

///|
fn field_name_at(fields : Array[ArchiveField], index : Int) -> String {
  for field in fields {
    if field.index == index {
      return field.term
    }
  }
  ""
}

///|
fn mapped_table(core : ArchiveFile, source : String) -> @csv_reader.CsvTable {
  let table = @csv_reader.parse(source)
  let headers : Array[String] = []
  for index, header in table.headers {
    let mapped = field_name_at(core.fields, index)
    if mapped.is_empty() {
      headers.push(header)
    } else {
      headers.push(mapped)
    }
  }
  { headers, rows: table.rows, delimiter: table.delimiter }
}

///|
pub fn parse_occurrence_text(
  manifest : ArchiveManifest,
  source : String,
) -> @darwincore.Dataset? {
  match manifest.core {
    Some(core) if core_type(core.row_type) == OccurrenceCore =>
      Some(@ecodata.from_table(mapped_table(core, source)))
    _ => None
  }
}

///|
pub fn parse_meta_xml(meta_xml : String) -> ArchiveManifest {
  let core = match meta_xml.split("<core").to_array() {
    parts if parts.length() >= 2 => {
      let core_xml = parts[1].split("</core>").to_array()[0].to_owned()
      let row_type = match attribute_value(core_xml, "rowType") {
        Some(value) => value
        None => row_type_from_meta(core_xml)
      }
      let fields = parse_fields(core_xml)
      let id_index = match core_xml.split("<id").to_array() {
        id_parts if id_parts.length() >= 2 =>
          match attribute_value(id_parts[1].to_owned(), "index") {
            Some(value) => value
            None => ""
          }
        _ => ""
      }
      {
        row_type,
        location: match element_text(core_xml, "location") {
          Some(value) => value
          None => ""
        },
        id_field: match parse_int_local(id_index) {
          Some(index) => field_name_at(fields, index)
          None => ""
        },
        fields,
      }
    }
    _ => return { core: None, extensions: [] }
  }
  { core: Some(core), extensions: [] }
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
