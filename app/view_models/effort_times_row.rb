# frozen_string_literal: true

class EffortTimesRow
  include ActiveModel::Serialization
  include PersonalInfo, TimeFormats

  EXPORT_ATTRIBUTES = [:overall_rank, :gender_rank, :bib_number, :first_name, :last_name, :gender, :age, :state_code, :country_code, :flexible_geolocation]

  attr_reader :effort, :display_style
  delegate :id, :first_name, :last_name, :full_name, :gender, :bib_number, :age, :city, :state_code, :country_code, :data_status,
           :bad?, :questionable?, :good?, :confirmed?, :segment_time, :overall_rank, :gender_rank, :start_offset,
           :stopped?, :dropped?, :finished?, to: :effort

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:effort, :lap_splits, :split_times],
                           exclusive: [:effort, :lap_splits, :split_times, :display_style],
                           class: self.class)
    @effort = args[:effort] # Use an enriched effort for optimal performance
    @lap_splits = args[:lap_splits]
    @split_times = args[:split_times]
    @display_style = args[:display_style]
  end

  def total_time_in_aid
    time_clusters.map(&:time_in_aid).compact.sum
  end

  def total_segment_time
    time_clusters.map(&:segment_time).compact.sum
  end

  def time_clusters
    @time_clusters ||= lap_splits.map do |lap_split|
      TimeCluster.new(finish: finish_cluster?(lap_split),
                      split_times_data: related_split_times(lap_split))
    end
  end

  private

  attr_reader :lap_splits, :split_times

  def indexed_split_times
    @indexed_split_times ||= split_times.index_by(&:time_point)
  end

  def finish_cluster?(lap_split)
    if multiple_laps?
      cluster_includes_last_data?(lap_split)
    else
      lap_split.split.finish?
    end
  end

  def cluster_includes_last_data?(lap_split)
    related_split_times(lap_split).compact.include?(last_split_time)
  end

  def related_split_times(lap_split)
    lap_split.time_points.map { |time_point| indexed_split_times.fetch(time_point, SplitTimeData.new) }
  end

  def last_split_time
    @last_split_time ||=
        lap_splits.flat_map(&:time_points).map { |time_point| indexed_split_times[time_point] }.compact.last
  end

  def lap_split_keys
    @lap_split_keys ||= lap_splits.map(&:key)
  end

  def multiple_laps?
    effort.laps_required != 1
  end
end
