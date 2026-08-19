///|
fn normalize_key(text : String) -> String {
  text
  .trim()
  .to_owned()
  .to_lower()
  .replace_all(old="_", new="")
  .replace_all(old="-", new="")
  .replace_all(old=" ", new="")
}

///|
fn row_field(
  table : @csv_reader.CsvTable,
  row : Array[String],
  aliases : Array[String],
) -> String? {
  for field_alias in aliases {
    let needle = normalize_key(field_alias)
    for index, header in table.headers {
      if normalize_key(header) == needle && index < row.length() {
        let value = row[index].trim().to_owned()
        if !value.is_empty() {
          return Some(value)
        }
      }
    }
  }
  None
}

///|
fn maybe_text(value : String?) -> String? {
  match value {
    Some(text) if !text.trim().is_empty() => Some(text.trim().to_owned())
    _ => None
  }
}

///|
fn parse_int_local(text : String) -> Int? {
  let trimmed = text.trim()
  if trimmed.is_empty() {
    return None
  }
  let mut sign = 1
  let mut value = 0
  let mut index = 0
  let mut valid = true
  trimmed
  .iter()
  .each(ch => {
    if index == 0 && ch == '-' {
      sign = -1
    } else if index == 0 && ch == '+' {
      ()
    } else if ch >= '0' && ch <= '9' {
      value = value * 10 + (ch.to_int() - '0'.to_int())
    } else {
      valid = false
    }
    index = index + 1
  })
  if valid && index > 0 {
    Some(value * sign)
  } else {
    None
  }
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
  let mut seen_dot = false
  let mut index = 0
  let mut valid = true
  trimmed
  .iter()
  .each(ch => {
    if index == 0 && ch == '-' {
      sign = -1.0
    } else if index == 0 && ch == '+' {
      ()
    } else if ch == '.' && !seen_dot {
      seen_dot = true
      after_dot = true
    } else if ch >= '0' && ch <= '9' {
      let digit = (ch.to_int() - '0'.to_int()).to_double()
      seen_digit = true
      if after_dot {
        value = value + digit * factor
        factor = factor / 10.0
      } else {
        value = value * 10.0 + digit
      }
    } else {
      valid = false
    }
    index = index + 1
  })
  if valid && seen_digit {
    Some(value * sign)
  } else {
    None
  }
}

///|
fn optional_int(value : String?) -> Int? {
  match value {
    Some(text) => parse_int_local(text)
    None => None
  }
}

///|
fn optional_double(value : String?) -> Double? {
  match value {
    Some(text) => parse_double_local(text)
    None => None
  }
}

///|
fn occurrence_from_row(
  table : @csv_reader.CsvTable,
  row : Array[String],
  fallback_index : Int,
) -> @darwincore.OccurrenceRecord {
  let occurrence_id = match
    row_field(table, row, [
      "occurrenceID", "id", "recordID", "记录编号", "记录ID",
    ]) {
    Some(value) => value
    None => "ROW-" + (fallback_index + 1).to_string()
  }
  let scientific_name = match
    row_field(table, row, [
      "scientificName", "物种名称", "拉丁学名", "学名", "species", "taxon",
    ]) {
    Some(value) => value
    None => ""
  }
  let latitude_text = row_field(table, row, [
    "decimalLatitude", "latitude", "lat", "纬度",
  ])
  let longitude_text = row_field(table, row, [
    "decimalLongitude", "longitude", "lon", "lng", "经度",
  ])
  {
    occurrence_id,
    event_id: maybe_text(
      row_field(table, row, [
        "eventID", "事件ID", "采样事件", "samplingEventID",
      ]),
    ),
    scientific_name,
    vernacular_name: maybe_text(
      row_field(table, row, ["vernacularName", "中文名", "俗名"]),
    ),
    kingdom: maybe_text(row_field(table, row, ["kingdom", "界"])),
    phylum: maybe_text(row_field(table, row, ["phylum", "门"])),
    class_name: maybe_text(row_field(table, row, ["class", "className", "纲"])),
    order_name: maybe_text(row_field(table, row, ["order", "目"])),
    family: maybe_text(row_field(table, row, ["family", "科"])),
    genus: maybe_text(row_field(table, row, ["genus", "属"])),
    specific_epithet: maybe_text(
      row_field(table, row, ["specificEpithet", "种加词"]),
    ),
    taxon_rank: maybe_text(row_field(table, row, ["taxonRank", "分类等级"])),
    event_date: maybe_text(
      row_field(table, row, [
        "eventDate", "date", "观察时间", "采样时间", "日期",
      ]),
    ),
    individual_count: optional_int(
      row_field(table, row, ["individualCount", "count", "数量", "个体数"]),
    ),
    coordinate: {
      latitude: optional_double(latitude_text),
      longitude: optional_double(longitude_text),
      uncertainty_meters: optional_double(
        row_field(table, row, [
          "coordinateUncertaintyInMeters", "坐标不确定性",
        ]),
      ),
      verbatim: maybe_text(
        row_field(table, row, ["verbatimCoordinates", "原始坐标"]),
      ),
    },
    locality: maybe_text(
      row_field(table, row, ["locality", "地点", "样区", "保护区"]),
    ),
    observer: maybe_text(
      row_field(table, row, ["recordedBy", "observer", "观察者", "记录人"]),
    ),
    observer_contact: maybe_text(
      row_field(table, row, [
        "observerContact", "email", "phone", "联系方式", "邮箱", "电话",
        "手机",
      ]),
    ),
    basis_of_record: maybe_text(
      row_field(table, row, ["basisOfRecord", "记录类型"]),
    ),
    occurrence_status: maybe_text(
      row_field(table, row, ["occurrenceStatus", "出现状态"]),
    ),
    remarks: maybe_text(
      row_field(table, row, ["occurrenceRemarks", "remarks", "备注", "note"]),
    ),
  }
}

///|
pub fn from_table(table : @csv_reader.CsvTable) -> @darwincore.Dataset {
  let occurrences : Array[@darwincore.OccurrenceRecord] = []
  for index, row in table.rows {
    occurrences.push(occurrence_from_row(table, row, index))
  }
  { occurrences, events: [], locations: [], measurements: [] }
}

///|
pub fn read_csv_string(source : String) -> @darwincore.Dataset {
  from_table(@csv_reader.parse(source))
}

///|
pub fn read_tsv_string(source : String) -> @darwincore.Dataset {
  from_table(@csv_reader.parse_tsv(source))
}

///|
pub fn read_csv(bytes : Bytes) -> @darwincore.Dataset {
  read_csv_string(bytes.to_string())
}
