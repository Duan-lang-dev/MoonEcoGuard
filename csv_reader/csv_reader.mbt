///|
pub(all) enum Delimiter {
  Comma
  Tab
} derive(Eq, Debug)

///|
pub(all) struct CsvTable {
  headers : Array[String]
  rows : Array[Array[String]]
  delimiter : Delimiter
} derive(Eq, Debug)

///|
fn delimiter_char(delimiter : Delimiter) -> Char {
  match delimiter {
    Comma => ','
    Tab => '\t'
  }
}

///|
fn strip_cr(text : String) -> String {
  match text.strip_suffix("\r") {
    Some(prefix) => prefix.to_owned()
    None => text
  }
}

///|
fn parse_line(line : String, delimiter : Char) -> Array[String] {
  let values : Array[String] = []
  let mut current = ""
  let mut in_quotes = false
  let mut pending_quote = false
  line
  .iter()
  .each(ch => {
    if pending_quote {
      if ch == '"' {
        current = current + "\""
        pending_quote = false
      } else {
        in_quotes = false
        pending_quote = false
        if ch == delimiter {
          values.push(current.trim().to_owned())
          current = ""
        } else {
          current = current + "\{ch}"
        }
      }
    } else if ch == '"' {
      if in_quotes {
        pending_quote = true
      } else if current.trim().is_empty() {
        in_quotes = true
      } else {
        current = current + "\{ch}"
      }
    } else if ch == delimiter && !in_quotes {
      values.push(current.trim().to_owned())
      current = ""
    } else {
      current = current + "\{ch}"
    }
  })
  values.push(current.trim().to_owned())
  values
}

///|
pub fn parse(source : String, delimiter? : Delimiter = Comma) -> CsvTable {
  let rows : Array[Array[String]] = []
  let mut headers : Array[String] = []
  let delim = delimiter_char(delimiter)
  let mut saw_header = false
  for raw_line in source.split("\n") {
    let line = strip_cr(raw_line.to_owned())
    if line.trim().is_empty() {
      continue
    }
    let parsed = parse_line(line, delim)
    if saw_header {
      rows.push(parsed)
    } else {
      headers = parsed.map(header => header.trim().to_owned())
      saw_header = true
    }
  }
  { headers, rows, delimiter }
}

///|
pub fn parse_tsv(source : String) -> CsvTable {
  parse(source, delimiter=Tab)
}

///|
pub fn CsvTable::header_index(self : CsvTable, name : String) -> Int? {
  let needle = name.trim().to_owned().to_lower()
  for index, header in self.headers {
    if header.trim().to_owned().to_lower() == needle {
      return Some(index)
    }
  }
  None
}

///|
pub fn CsvTable::cell(
  self : CsvTable,
  row : Array[String],
  name : String,
) -> String? {
  match self.header_index(name) {
    Some(index) if index < row.length() => Some(row[index])
    _ => None
  }
}

///|
pub fn CsvTable::shape(self : CsvTable) -> (Int, Int) {
  (self.rows.length(), self.headers.length())
}
