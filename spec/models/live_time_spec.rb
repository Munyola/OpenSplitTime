require 'rails_helper'

# t.integer  "event_id",        null: false
# t.integer  "lap"
# t.integer  "split_id",        null: false
# t.string   "split_extension"
# t.string   "wave"
# t.integer  "bib_number",      null: false
# t.string   "absolute_time",   null: false
# t.boolean  "with_pacer"
# t.boolean  "stopped_here"
# t.string   "remarks"
# t.integer  "source"
# t.string   "batch"
# t.integer  "split_time_id"

RSpec.describe LiveTime, type: :model do
  let(:effort) { create(:effort, event: event) }
  let(:event) { create(:event, course: course) }
  let(:split) { create(:split, course: course) }
  let(:course) { create(:course) }
  let(:in_bitkey) { SubSplit::IN_BITKEY }
  let(:out_bitkey) { SubSplit::OUT_BITKEY }

  describe '#initialize' do
    let(:time_string) { '08:00:00' }
    let(:source) { 'ost-test' }
    before do
      event.splits << split
    end

    it 'is valid when created with an event, split, bitkey, bib_number, absolute_time, and source' do
      live_time = LiveTime.new(event: event, split: split, bitkey: 1, bib_number: 101, absolute_time: time_string, source: source)
      expect(live_time).to be_valid
    end

    it 'is invalid when no event is provided' do
      live_time = LiveTime.new(split: split, bib_number: 101, absolute_time: time_string)
      expect(live_time).to be_invalid
      expect(live_time.errors.full_messages).to include("Event can't be blank")
    end

    it 'is invalid when no split is provided' do
      live_time = LiveTime.new(event: event, bib_number: 101, absolute_time: time_string)
      expect(live_time).to be_invalid
      expect(live_time.errors.full_messages).to include("Split can't be blank")
    end

    it 'is invalid when no bib_number is provided' do
      live_time = LiveTime.new(event: event, split: split, absolute_time: time_string)
      expect(live_time).to be_invalid
      expect(live_time.errors.full_messages).to include("Bib number can't be blank")
    end

    it 'is invalid when no absolute_time is provided' do
      live_time = LiveTime.new(event: event, split: split, bib_number: 101)
      expect(live_time).to be_invalid
      expect(live_time.errors.full_messages).to include("Absolute time can't be blank")
    end

    it 'is invalid when the event.course is not the same as the split.course' do
      new_split = create(:split)
      live_time = LiveTime.new(event: event, split: new_split, bib_number: 101, absolute_time: time_string)
      expect(live_time).to be_invalid
      expect(live_time.errors.full_messages).to include('Effort the event.course_id does not resolve with the split.course_id')
    end

    it 'is invalid when the split is not the same as the split_time.split' do
      new_split = create(:split)
      split_time = SplitTime.create(effort: effort, split: new_split)
      live_time = LiveTime.new(event: event, split: split, bib_number: 101, absolute_time: time_string, split_time: split_time)
      expect(live_time).to be_invalid
      expect(live_time.errors.full_messages).to include('Split time the split_id is not the same as the split_time.split_id')
    end

    it 'saves a valid record to the database' do
      create(:live_time, event: event, split: split)
      expect(LiveTime.count).to eq(1)
    end
  end

  describe '#split_time' do
    let(:split_time) { create(:split_time, effort: effort, split: split) }
    before do
      event.splits << split
    end

    it 'when related split_time is deleted, sets live_time.split_time to nil' do
      live_time = create(:live_time, event: event, split: split, split_time: split_time)
      expect(live_time.split_time).to eq(split_time)
      SplitTime.last.destroy
      live_time.reload
      expect(live_time.split_time).to be_nil
    end
  end

  describe '#event_slug' do
    let!(:event) { create(:event, slug: 'test-event') }

    it 'returns the slug of the associated event' do
      live_time = LiveTime.new(event: event)
      expect(live_time.event_slug).to eq(event.slug)
    end
  end

  describe '#event_slug=' do
    let!(:event) { create(:event) }
    let(:live_time) { LiveTime.new }

    it 'finds the event having a slug equal to the provided param and sets event_id' do
      slug = event.slug
      live_time.event_slug = slug
      expect(live_time.event).to eq(event)
    end

    it 'sets the event to nil if the slug is not found' do
      live_time.event_slug = 'nonexistent-event'
      expect(live_time.event_id).to be_nil
    end
  end

  describe '#split_slug' do
    let!(:split) { create(:split, slug: 'test-split') }

    it 'returns the slug of the associated split' do
      live_time = LiveTime.new(split: split)
      expect(live_time.split_slug).to eq(split.slug)
    end
  end

  describe '#split_slug=' do
    let!(:split) { create(:split, slug: 'test-split') }
    let(:live_time) { LiveTime.new }

    it 'finds the split having a slug equal to the provided param and sets split_id' do
      live_time.split_slug = 'test-split'
      expect(live_time.split).to eq(split)
    end

    it 'sets the split to nil if the slug is not found' do
      live_time.split_slug = 'nonexistent-split'
      expect(live_time.split_id).to be_nil
    end
  end

  describe '#sub_split_kind' do
    context 'when bitkey is the in_bitkey' do
      let(:live_time) { LiveTime.new(bitkey: in_bitkey) }

      it 'returns "in" when bitkey is the in_bitkey' do
        expect(live_time.sub_split_kind).to eq('In')
      end
    end

    context 'when bitkey is the out_bitkey' do
      let(:live_time) { LiveTime.new(bitkey: out_bitkey) }

      it 'returns "in" when bitkey is the in_bitkey' do
        expect(live_time.sub_split_kind).to eq('Out')
      end
    end
  end

  describe '#sub_split_kind=' do
    context 'when sub_split_kind is "in"' do
      let(:sub_split_kind) { 'in' }

      it 'sets the bitkey to the in_bitkey' do
        live_time = LiveTime.new(sub_split_kind: sub_split_kind)
        expect(live_time.bitkey).to eq(in_bitkey)
      end
    end

    context 'when sub_split_kind is "out"' do
      let(:sub_split_kind) { 'out' }

      it 'sets the bitkey to the in_bitkey' do
        live_time = LiveTime.new(sub_split_kind: sub_split_kind)
        expect(live_time.bitkey).to eq(out_bitkey)
      end
    end

    context 'when sub_split_kind has different capitalization' do
      let(:sub_split_kind) { 'OUT' }

      it 'sets the bitkey as expected' do
        live_time = LiveTime.new(sub_split_kind: sub_split_kind)
        expect(live_time.bitkey).to eq(out_bitkey)
      end
    end

    context 'when sub_split_kind is a symbol' do
      let(:sub_split_kind) { :out }

      it 'sets the bitkey as expected' do
        live_time = LiveTime.new(sub_split_kind: sub_split_kind)
        expect(live_time.bitkey).to eq(out_bitkey)
      end
    end

    context 'when sub_split_kind is an empty string' do
      let(:sub_split_kind) { '' }

      it 'sets the bitkey to nil' do
        live_time = LiveTime.new(sub_split_kind: sub_split_kind)
        expect(live_time.bitkey).to eq(nil)
      end
    end

    context 'when sub_split_kind is nil' do
      let(:sub_split_kind) { nil }

      it 'sets the bitkey to nil' do
        live_time = LiveTime.new(sub_split_kind: sub_split_kind)
        expect(live_time.bitkey).to eq(nil)
      end
    end
  end

  describe '#effort' do
    context 'when the related event includes an effort with a bib_number matching the live_time.bib_number' do
      it 'returns the effort' do
        live_time = build_stubbed(:live_time, event: event, bib_number: effort.bib_number)
        expect(live_time.effort).to eq(effort)
      end
    end

    context 'when the related event does not include an effort with a matching bib_number' do
      it 'returns nil' do
        live_time = build_stubbed(:live_time, event: event, bib_number: 0)
        expect(live_time.effort).to eq(nil)
      end
    end
  end

  describe '#effort_full_name' do
    context 'when the related event includes an effort with a bib_number matching the live_time.bib_number' do
      it 'returns the full name of the effort' do
        live_time = build_stubbed(:live_time, event: event, bib_number: effort.bib_number)
        expect(live_time.effort_full_name).to eq(effort.full_name)
      end
    end

    context 'when the related event does not include an effort with a matching bib_number' do
      it 'returns [Bib not found]' do
        live_time = build_stubbed(:live_time, event: event, bib_number: 0)
        expect(live_time.effort_full_name).to eq('[Bib not found]')
      end
    end
  end
end
