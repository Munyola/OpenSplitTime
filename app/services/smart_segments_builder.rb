# frozen_string_literal: true

class SmartSegmentsBuilder
  def self.segments(args)
    new(args).segments
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:event, :time_points, :times_container],
                           exclusive: [:event, :time_points, :times_container],
                           class: self.class)
    @event = args[:event]
    @time_points = args[:time_points]
    @times_container = args[:times_container]
  end

  def segments
    result = []
    begin_index = end_index = 0

    while end_index < time_points.size
      begin_point = time_points[begin_index]
      end_point = time_points[end_index]
      segment = Segment.new(begin_point: begin_point,
                            end_point: end_point,
                            begin_lap_split: lap_split_from_time_point(begin_point),
                            end_lap_split: lap_split_from_time_point(end_point))

      if times_container.segment_time(segment)
        result << segment
        begin_index = end_index
      end
      end_index += 1
    end

    result
  end

  private

  attr_reader :event, :time_points, :times_container

  def lap_split_from_time_point(time_point)
    LapSplit.new(time_point.lap, indexed_splits[time_point.split_id])
  end

  def indexed_splits
    @indexed_splits ||= event.ordered_splits.index_by(&:id)
  end
end
