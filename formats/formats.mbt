///|
fn escape_json(text : String) -> String {
  text
  .replace_all(old="\\", new="\\\\")
  .replace_all(old="\"", new="\\\"")
  .replace_all(old="\n", new=" ")
  .replace_all(old="\r", new=" ")
}

///|
fn quote_json(text : String) -> String {
  "\"" + escape_json(text) + "\""
}

///|
fn quote_csv(text : String) -> String {
  "\"" +
  text.replace_all(old="\"", new="\"\"").replace_all(old="\n", new=" ") +
  "\""
}

///|
fn opt_text(value : String?) -> String {
  match value {
    Some(text) => text
    None => ""
  }
}

///|
fn opt_int(value : Int?) -> String {
  match value {
    Some(v) => v.to_string()
    None => ""
  }
}

///|
fn opt_double(value : Double?) -> String {
  match value {
    Some(v) => v.to_string()
    None => ""
  }
}

///|
fn severity_text(severity : @validation.Severity) -> String {
  match severity {
    @validation.Severity::Info => "Info"
    @validation.Severity::Warning => "Warning"
    @validation.Severity::Error => "Error"
  }
}

///|
pub fn validation_markdown(report : @validation.ValidationReport) -> String {
  let lines : Array[String] = []
  lines.push("# MoonEcoGuard validation report")
  lines.push("")
  lines.push("| Metric | Value |")
  lines.push("| --- | ---: |")
  lines.push("| Records | \{report.record_count} |")
  lines.push("| Valid | \{report.valid_count} |")
  lines.push("| Warnings | \{report.warning_count} |")
  lines.push("| Errors | \{report.error_count} |")
  lines.push("")
  lines.push("## Diagnostics")
  if report.diagnostics.is_empty() {
    lines.push("")
    lines.push("No diagnostics.")
  } else {
    lines.push("")
    lines.push("| Severity | Code | Record | Field | Message | Suggestion |")
    lines.push("| --- | --- | --- | --- | --- | --- |")
    for issue in report.diagnostics {
      lines.push(
        "| " +
        severity_text(issue.severity) +
        " | " +
        issue.code +
        " | " +
        opt_text(issue.occurrence_id) +
        " | " +
        opt_text(issue.field) +
        " | " +
        issue.message +
        " | " +
        opt_text(issue.suggestion) +
        " |",
      )
    }
  }
  lines.join("\n")
}

///|
pub fn stats_markdown(stats : @statistics.DatasetStats) -> String {
  [
    "# MoonEcoGuard dataset statistics",
    "",
    "| Metric | Value |",
    "| --- | ---: |",
    "| Records | \{stats.record_count} |",
    "| Unique taxa | \{stats.unique_taxa} |",
    "| Georeferenced records | \{stats.georeferenced_count} |",
    "| Zero-zero coordinates | \{stats.zero_zero_count} |",
    "| Missing scientificName | \{stats.missing_scientific_name_count} |",
    "| Sensitive records | \{stats.sensitive_record_count} |",
  ].join("\n")
}

///|
fn occurrence_json(record : @darwincore.OccurrenceRecord) -> String {
  let fields : Array[String] = []
  fields.push("\"occurrenceID\":" + quote_json(record.occurrence_id))
  fields.push("\"scientificName\":" + quote_json(record.scientific_name))
  match record.event_id {
    Some(v) => fields.push("\"eventID\":" + quote_json(v))
    None => ()
  }
  match record.vernacular_name {
    Some(v) => fields.push("\"vernacularName\":" + quote_json(v))
    None => ()
  }
  match record.event_date {
    Some(v) => fields.push("\"eventDate\":" + quote_json(v))
    None => ()
  }
  match record.individual_count {
    Some(v) => fields.push("\"individualCount\":" + v.to_string())
    None => ()
  }
  match record.coordinate.latitude {
    Some(v) => fields.push("\"decimalLatitude\":" + v.to_string())
    None => ()
  }
  match record.coordinate.longitude {
    Some(v) => fields.push("\"decimalLongitude\":" + v.to_string())
    None => ()
  }
  match record.locality {
    Some(v) => fields.push("\"locality\":" + quote_json(v))
    None => ()
  }
  "{" + fields.join(",") + "}"
}

///|
pub fn to_json(dataset : @darwincore.Dataset) -> String {
  "{\"occurrences\":[" +
  dataset.occurrences.map(occurrence_json).join(",") +
  "]}"
}

///|
fn geojson_feature(record : @darwincore.OccurrenceRecord) -> String? {
  match (record.coordinate.latitude, record.coordinate.longitude) {
    (Some(lat), Some(lon)) => {
      let props = [
        "\"occurrenceID\":" + quote_json(record.occurrence_id),
        "\"scientificName\":" + quote_json(record.scientific_name),
        "\"eventDate\":" + quote_json(opt_text(record.event_date)),
        "\"individualCount\":" + quote_json(opt_int(record.individual_count)),
      ].join(",")
      Some(
        "{\"type\":\"Feature\",\"geometry\":{\"type\":\"Point\",\"coordinates\":[" +
        lon.to_string() +
        "," +
        lat.to_string() +
        "]},\"properties\":{" +
        props +
        "}}",
      )
    }
    _ => None
  }
}

///|
pub fn to_geojson(dataset : @darwincore.Dataset) -> String {
  let features : Array[String] = []
  for record in dataset.occurrences {
    match geojson_feature(record) {
      Some(feature) => features.push(feature)
      None => ()
    }
  }
  "{\"type\":\"FeatureCollection\",\"features\":[" + features.join(",") + "]}"
}

///|
pub fn occurrences_csv(dataset : @darwincore.Dataset) -> String {
  let rows : Array[String] = []
  rows.push(
    "occurrenceID,eventID,scientificName,vernacularName,eventDate,decimalLatitude,decimalLongitude,coordinateUncertaintyInMeters,recordedBy,observerContact,individualCount,locality,occurrenceRemarks",
  )
  for record in dataset.occurrences {
    rows.push(
      [
        quote_csv(record.occurrence_id),
        quote_csv(opt_text(record.event_id)),
        quote_csv(record.scientific_name),
        quote_csv(opt_text(record.vernacular_name)),
        quote_csv(opt_text(record.event_date)),
        opt_double(record.coordinate.latitude),
        opt_double(record.coordinate.longitude),
        opt_double(record.coordinate.uncertainty_meters),
        quote_csv(opt_text(record.observer)),
        quote_csv(opt_text(record.observer_contact)),
        opt_int(record.individual_count),
        quote_csv(opt_text(record.locality)),
        quote_csv(opt_text(record.remarks)),
      ].join(","),
    )
  }
  rows.join("\n")
}
