///|
let fixture_meta =
  #|<?xml version="1.0" encoding="UTF-8"?>
  #|<archive xmlns="http://rs.tdwg.org/dwc/text/" metadata="eml.xml">
  #|  <core encoding="UTF-8" fieldsTerminatedBy="," linesTerminatedBy="\\n" rowType="http://rs.tdwg.org/dwc/terms/Occurrence">
  #|    <files><location>occurrence.txt</location></files>
  #|    <id index="0" />
  #|    <field index="0" term="http://rs.tdwg.org/dwc/terms/occurrenceID" />
  #|    <field index="1" term="http://rs.tdwg.org/dwc/terms/scientificName" />
  #|    <field index="2" term="http://rs.tdwg.org/dwc/terms/eventDate" />
  #|    <field index="3" term="http://rs.tdwg.org/dwc/terms/decimalLatitude" />
  #|    <field index="4" term="http://rs.tdwg.org/dwc/terms/decimalLongitude" />
  #|  </core>
  #|</archive>

///|
let fixture_occurrence =
  #|raw-0,raw-1,raw-2,raw-3,raw-4
  #|OBS-DWCA-001,Cathaya argyrophylla,2026-05-12,26.123456,108.567890
  #|OBS-DWCA-002,Ailuropoda melanoleuca,2026-05-13,31.482100,104.923100

///|
test "parse DwCA manifest mappings and occurrence core" {
  let manifest = @dwca.parse_meta_xml(fixture_meta)
  match manifest.core {
    Some(core) => {
      assert_eq(core.row_type, "http://rs.tdwg.org/dwc/terms/Occurrence")
      assert_eq(core.location, "occurrence.txt")
      assert_eq(core.id_field, "occurrenceID")
      assert_eq(core.fields.length(), 5)
      assert_eq(core.fields[0].term, "occurrenceID")
      assert_eq(core.fields[4].term, "decimalLongitude")
    }
    None => fail("expected occurrence core")
  }
  match @dwca.parse_occurrence_text(manifest, fixture_occurrence) {
    Some(dataset) => {
      assert_eq(dataset.occurrences.length(), 2)
      assert_eq(dataset.occurrences[0].occurrence_id, "OBS-DWCA-001")
      assert_eq(
        dataset.occurrences[1].scientific_name,
        "Ailuropoda melanoleuca",
      )
      match dataset.occurrences[0].coordinate.latitude {
        Some(latitude) => assert_true(latitude > 26.12 && latitude < 26.13)
        None => fail("expected mapped latitude")
      }
    }
    None => fail("expected occurrence dataset")
  }
}

///|
test "parse DwCA rejects non-occurrence core" {
  let event_meta =
    #|<archive><core rowType="http://rs.tdwg.org/dwc/terms/Event">
    #|<files><location>event.txt</location></files>
    #|<id index="0" />
    #|</core></archive>
  let manifest = @dwca.parse_meta_xml(event_meta)
  assert_true(@dwca.parse_occurrence_text(manifest, "id\nE-001") is None)
}
