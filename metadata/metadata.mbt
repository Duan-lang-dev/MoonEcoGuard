///|
pub(all) struct ResourceMetadata {
  title : String
  abstract_text : String
  creator : String
  contact_email : String
  license : String
} derive(Eq, Debug)

///|
pub fn default_metadata() -> ResourceMetadata {
  {
    title: "MoonEcoGuard biodiversity dataset",
    abstract_text: "Darwin Core style biodiversity survey data processed by MoonEcoGuard.",
    creator: "Duan-lang-dev",
    contact_email: "956327105@qq.com",
    license: "CC-BY-4.0",
  }
}

///|
pub fn eml_summary(metadata : ResourceMetadata) -> String {
  "# " +
  metadata.title +
  "\n\n" +
  metadata.abstract_text +
  "\n\nCreator: " +
  metadata.creator +
  " <" +
  metadata.contact_email +
  ">\nLicense: " +
  metadata.license
}
