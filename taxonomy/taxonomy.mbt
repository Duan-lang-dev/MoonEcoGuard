///|
pub(all) struct TaxonomyIssue {
  code : String
  message : String
  suggestion : String?
} derive(Eq, Debug)

///|
fn is_ascii_upper(ch : Char) -> Bool {
  ch >= 'A' && ch <= 'Z'
}

///|
fn is_ascii_lower(ch : Char) -> Bool {
  ch >= 'a' && ch <= 'z'
}

///|
fn looks_like_latin_word(text : StringView) -> Bool {
  !text.is_empty() &&
  text.all(fn(ch) { is_ascii_upper(ch) || is_ascii_lower(ch) || ch == '-' })
}

///|
fn starts_upper(text : StringView) -> Bool {
  let mut ok = false
  let mut seen = false
  text
  .iter()
  .each(ch => {
    if !seen {
      ok = is_ascii_upper(ch)
      seen = true
    }
  })
  ok
}

///|
fn starts_lower(text : StringView) -> Bool {
  let mut ok = false
  let mut seen = false
  text
  .iter()
  .each(ch => {
    if !seen {
      ok = is_ascii_lower(ch)
      seen = true
    }
  })
  ok
}

///|
pub fn normalize_spaces(text : String) -> String {
  text.split(" ").filter(part => !part.is_empty()).to_array().join(" ")
}

///|
pub fn normalize_scientific_name(text : String) -> String {
  normalize_spaces(text.trim().to_owned())
}

///|
pub fn scientific_name_issues(
  scientific_name : String,
  genus : String?,
) -> Array[TaxonomyIssue] {
  let issues : Array[TaxonomyIssue] = []
  let normalized = normalize_scientific_name(scientific_name)
  if normalized.is_empty() {
    issues.push({
      code: "DWG-108",
      message: "scientificName is empty",
      suggestion: None,
    })
    return issues
  }
  let parts = normalized.split(" ").filter(part => !part.is_empty()).to_array()
  if parts.length() >= 1 {
    let g = parts[0]
    if !looks_like_latin_word(g) || !starts_upper(g) {
      issues.push({
        code: "DWG-201",
        message: "genus should look like a Latin capitalized word",
        suggestion: None,
      })
    }
    match genus {
      Some(expected) if !expected.trim().is_empty() && expected.trim() != g =>
        issues.push({
          code: "DWG-202",
          message: "genus field conflicts with scientificName",
          suggestion: Some(
            "Use genus " + g.to_owned() + " or review the scientificName",
          ),
        })
      _ => ()
    }
  }
  if parts.length() >= 2 {
    let epithet = parts[1]
    if !looks_like_latin_word(epithet) || !starts_lower(epithet) {
      issues.push({
        code: "DWG-203",
        message: "specific epithet should be lowercase Latin text",
        suggestion: None,
      })
    }
  }
  let lower = normalized.to_lower()
  match lower {
    "panada melanoleuca" =>
      issues.push({
        code: "DWG-204",
        message: "possible spelling correction: Panada -> Ailuropoda",
        suggestion: Some("Ailuropoda melanoleuca"),
      })
    _ => ()
  }
  issues
}
