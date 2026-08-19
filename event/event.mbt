///|
pub fn sampling_event(
  event_id : String,
  event_date? : String,
  locality? : String,
) -> @darwincore.SamplingEvent {
  {
    event_id,
    parent_event_id: None,
    event_date,
    end_date: None,
    locality,
    sampling_protocol: None,
    sample_size_value: None,
    sample_size_unit: None,
  }
}
