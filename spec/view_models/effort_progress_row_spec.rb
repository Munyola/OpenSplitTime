# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EffortProgressRow do
  let(:event) { build_stubbed(:event_functional, laps_required: 3, splits_count: 4) }
  let(:splits) { event.splits }
  let(:efforts) { event.efforts }

  describe '#extract_attributes' do
    it 'returns a hash with keys being the provided attributes and values being values of corresponding methods' do
      split = event.splits.first
      effort = event.efforts.first
      aid_station = AidStation.new(event: event, split: split)
      aid_station_detail = AidStationDetail.new(event: event, aid_station: aid_station)
      aid_detail_row = EffortProgressAidDetail.new(effort: effort,
                                                   event_framework: aid_station_detail,
                                                   lap: 1,
                                                   effort_split_times: [],
                                                   times_container: SegmentTimesContainer.new(calc_model: :terrain))
      actual = aid_detail_row.extract_attributes(:full_name, :bio_historic)
      expected = {full_name: aid_detail_row.full_name, bio_historic: aid_detail_row.bio_historic}
      expect(actual).to eq(expected)
    end
  end
end
