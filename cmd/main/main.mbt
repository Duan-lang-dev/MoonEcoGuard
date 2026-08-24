///|
fn print_usage() -> Unit {
  println(
    "MoonEcoGuard - biodiversity data quality and sensitive coordinate protection",
  )
  println("")
  println("Usage:")
  println("  moon run cmd/main -- validate FILE [--policy policy.json]")
  println(
    "  moon run cmd/main -- report FILE --format markdown [--policy policy.json]",
  )
  println(
    "  moon run cmd/main -- protect FILE --policy policy.json [--output public.csv]",
  )
  println("  moon run cmd/main -- convert FILE --format geojson")
  println("  moon run cmd/main -- stats FILE [--policy policy.json]")
  println(
    "  moon run cmd/main -- geo-check FILE --bounds minLat,minLon,maxLat,maxLon",
  )
  println("  moon run cmd/main -- diff private.csv public.csv")
  println("  moon run cmd/main -- dwca-check DIRECTORY")
  println("  moon run cmd/main -- dwca-convert DIRECTORY --format csv")
  println("")
  println(
    "Note: coordinate protection reduces disclosure risk but does not replace expert review.",
  )
}

///|
fn read_text(path : String) -> String? {
  Some(@fs.read_file_to_string(path)) catch {
    _ => None
  }
}

///|
fn read_dataset(path : String) -> @darwincore.Dataset? {
  match read_text(path) {
    None => None
    Some(text) =>
      if path.to_lower().has_suffix(".tsv") {
        Some(@ecodata.read_tsv_string(text))
      } else {
        Some(@ecodata.read_csv_string(text))
      }
  }
}

///|
fn arg_after(args : Array[String], flag : String) -> String? {
  let mut index = 0
  while index + 1 < args.length() {
    if args[index] == flag {
      return Some(args[index + 1])
    }
    index = index + 1
  }
  None
}

///|
fn parse_double_local(text : String) -> Double? {
  let trimmed = text.trim()
  if trimmed.is_empty() {
    return None
  }
  let mut sign = 1.0
  let mut value = 0.0
  let mut factor = 0.1
  let mut after_dot = false
  let mut seen_digit = false
  let mut index = 0
  trimmed
  .iter()
  .each(ch => {
    if index == 0 && ch == '-' {
      sign = -1.0
    } else if index == 0 && ch == '+' {
      ()
    } else if ch == '.' {
      after_dot = true
    } else if ch >= '0' && ch <= '9' {
      seen_digit = true
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
  if seen_digit {
    Some(value * sign)
  } else {
    None
  }
}

///|
fn parse_bounds(text : String) -> @geospatial.Bounds? {
  let parts = text.split(",").to_array()
  if parts.length() != 4 {
    return None
  }
  match
    (
      parse_double_local(parts[0].to_owned()),
      parse_double_local(parts[1].to_owned()),
      parse_double_local(parts[2].to_owned()),
      parse_double_local(parts[3].to_owned()),
    ) {
    (
      Some(min_latitude),
      Some(min_longitude),
      Some(max_latitude),
      Some(max_longitude),
    ) => Some({ min_latitude, min_longitude, max_latitude, max_longitude })
    _ => None
  }
}

///|
fn read_policy(args : Array[String]) -> @privacy.Policy? {
  match arg_after(args, "--policy") {
    Some(path) =>
      match read_text(path) {
        Some(text) => Some(@privacy.policy_from_json(text))
        None => None
      }
    None => Some(@privacy.default_policy())
  }
}

///|
fn policy_error(args : Array[String]) -> String {
  match arg_after(args, "--policy") {
    Some(path) => "Unable to read policy file: " + path
    None => "Unable to read policy file"
  }
}

///|
fn rules_from_policy(
  policy : @privacy.Policy,
  bounds : @geospatial.Bounds?,
) -> @validation.ValidationRules {
  {
    required_occurrence_id: true,
    required_scientific_name: true,
    require_event_ids_to_exist: false,
    sensitive_taxa: policy.sensitive_taxa,
    max_individual_count: 10000,
    coordinate_bounds: bounds,
  }
}

///|
fn command_validate(
  path : String,
  args : Array[String],
  bounds : @geospatial.Bounds?,
) -> Unit {
  match read_dataset(path) {
    None => println("Unable to read file: " + path)
    Some(dataset) =>
      match read_policy(args) {
        None => println(policy_error(args))
        Some(policy) => {
          let report = @validation.validate(
            dataset,
            rules=rules_from_policy(policy, bounds),
          )
          println("MoonEcoGuard validation report")
          println("Records: " + report.record_count.to_string())
          println("Valid:   " + report.valid_count.to_string())
          println("Warning: " + report.warning_count.to_string())
          println("Error:   " + report.error_count.to_string())
          for issue in report.diagnostics {
            let severity = match issue.severity {
              @validation.Severity::Info => "INFO"
              @validation.Severity::Warning => "WARNING"
              @validation.Severity::Error => "ERROR"
            }
            println(severity + " " + issue.code + " " + issue.message)
          }
        }
      }
  }
}

///|
fn command_report(path : String, args : Array[String]) -> Unit {
  match arg_after(args, "--format") {
    Some("markdown") =>
      match read_dataset(path) {
        None => println("Unable to read file: " + path)
        Some(dataset) =>
          match read_policy(args) {
            None => println(policy_error(args))
            Some(policy) => {
              let report = @validation.validate(
                dataset,
                rules=rules_from_policy(policy, None),
              )
              println(@formats.validation_markdown(report))
            }
          }
      }
    Some(format) => println("Unsupported report format: " + format)
    None => println("Missing report format; try --format markdown")
  }
}

///|
fn print_protection_summary(summary : @privacy.ProtectionSummary) -> Unit {
  println("Protection summary")
  println("Records:                  " + summary.record_count.to_string())
  println(
    "Sensitive records:        " + summary.sensitive_record_count.to_string(),
  )
  println(
    "Coordinates changed:      " + summary.coordinate_changed_count.to_string(),
  )
  println(
    "Coordinates removed:      " + summary.coordinate_removed_count.to_string(),
  )
  println(
    "Observer contacts removed: " +
    summary.observer_contact_removed_count.to_string(),
  )
  println(
    "Remarks redacted:         " + summary.remarks_redacted_count.to_string(),
  )
}

///|
fn command_protect(path : String, args : Array[String]) -> Unit {
  match read_dataset(path) {
    None => println("Unable to read file: " + path)
    Some(dataset) =>
      match read_policy(args) {
        None => println(policy_error(args))
        Some(policy) => {
          let result = @privacy.protect_with_summary(dataset, policy)
          print_protection_summary(result.summary)
          let output = @formats.occurrences_csv(result.dataset)
          match arg_after(args, "--output") {
            Some(out_path) => {
              let ok = try {
                @fs.write_string_to_file(out_path, output)
                true
              } catch {
                _ => false
              }
              if ok {
                println("Wrote protected CSV: " + out_path)
              } else {
                println("Unable to write protected CSV: " + out_path)
              }
            }
            None => println(output)
          }
        }
      }
  }
}

///|
fn command_convert(path : String, args : Array[String]) -> Unit {
  match read_dataset(path) {
    None => println("Unable to read file: " + path)
    Some(dataset) =>
      match arg_after(args, "--format") {
        Some("geojson") => println(@formats.to_geojson(dataset))
        Some("json") => println(@formats.to_json(dataset))
        _ => println("Unsupported format; try --format geojson")
      }
  }
}

///|
fn command_stats(path : String, args : Array[String]) -> Unit {
  match read_dataset(path) {
    None => println("Unable to read file: " + path)
    Some(dataset) =>
      match read_policy(args) {
        None => println(policy_error(args))
        Some(policy) =>
          println(
            @formats.stats_markdown(
              @statistics.summarize(
                dataset,
                sensitive_taxa=policy.sensitive_taxa,
              ),
            ),
          )
      }
  }
}

///|
fn read_dwca_dataset(path : String) -> @darwincore.Dataset? {
  let meta_path = path + "/meta.xml"
  match read_text(meta_path) {
    None => None
    Some(meta_xml) => {
      let manifest = @dwca.parse_meta_xml(meta_xml)
      match manifest.core {
        Some(core) if !core.location.is_empty() =>
          match read_text(path + "/" + core.location) {
            Some(source) => @dwca.parse_occurrence_text(manifest, source)
            None => None
          }
        _ => None
      }
    }
  }
}

///|
fn command_dwca_check(path : String) -> Unit {
  match read_text(path + "/meta.xml") {
    None => println("Unable to read DwCA meta.xml: " + path)
    Some(meta_xml) => {
      let manifest = @dwca.parse_meta_xml(meta_xml)
      match manifest.core {
        None => println("DwCA manifest has no supported core: " + path)
        Some(core) if core.location.is_empty() =>
          println("DwCA core has no location: " + path)
        Some(core) =>
          match read_dwca_dataset(path) {
            None => println("Unable to read DwCA core file: " + core.location)
            Some(dataset) => {
              println("MoonEcoGuard DwCA directory check")
              println("Core row type: " + core.row_type)
              println("Core location: " + core.location)
              println("Core ID field: " + core.id_field)
              println("Mapped fields: " + core.fields.length().to_string())
              println(
                "Occurrence records: " +
                dataset.occurrences.length().to_string(),
              )
            }
          }
      }
    }
  }
}

///|
fn command_dwca_convert(path : String, args : Array[String]) -> Unit {
  match arg_after(args, "--format") {
    Some("csv") =>
      match read_dwca_dataset(path) {
        None => println("Unable to read DwCA directory: " + path)
        Some(dataset) => println(@formats.occurrences_csv(dataset))
      }
    Some(format) => println("Unsupported DwCA format: " + format)
    None => println("Missing DwCA format; try --format csv")
  }
}

///|
fn command_diff(private_path : String, public_path : String) -> Unit {
  match (read_dataset(private_path), read_dataset(public_path)) {
    (Some(private_dataset), Some(public_dataset)) => {
      let result = @privacy.diff(private_dataset, public_dataset)
      println(
        "Private records:              " +
        result.private_record_count.to_string(),
      )
      println(
        "Public records:               " +
        result.public_record_count.to_string(),
      )
      println(
        "Matched records:              " + result.matched_count.to_string(),
      )
      println("Added records:                " + result.added_count.to_string())
      println(
        "Removed records:              " + result.removed_count.to_string(),
      )
      println(
        "Coordinates changed:          " +
        result.coordinate_changed_count.to_string(),
      )
      println(
        "Coordinates removed:          " +
        result.coordinate_removed_count.to_string(),
      )
      println(
        "Observer contacts changed:   " +
        result.observer_contact_changed_count.to_string(),
      )
      println(
        "Remarks changed:             " +
        result.remarks_changed_count.to_string(),
      )
    }
    _ => println("Unable to read one or both files")
  }
}

///|
fn main {
  let args = @env.args()
  if args.length() < 2 {
    print_usage()
    return
  }
  match args[1] {
    "validate" if args.length() >= 3 => command_validate(args[2], args, None)
    "report" if args.length() >= 3 => command_report(args[2], args)
    "protect" if args.length() >= 3 => command_protect(args[2], args)
    "convert" if args.length() >= 3 => command_convert(args[2], args)
    "stats" if args.length() >= 3 => command_stats(args[2], args)
    "geo-check" if args.length() >= 3 =>
      match arg_after(args, "--bounds") {
        None => println("Missing bounds; expected minLat,minLon,maxLat,maxLon")
        Some(value) =>
          match parse_bounds(value) {
            None => println("Invalid bounds: " + value)
            Some(bounds) => command_validate(args[2], args, Some(bounds))
          }
      }
    "diff" if args.length() >= 4 => command_diff(args[2], args[3])
    "dwca-check" if args.length() >= 3 => command_dwca_check(args[2])
    "dwca-convert" if args.length() >= 3 => command_dwca_convert(args[2], args)
    _ => print_usage()
  }
}
