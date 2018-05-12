# frozen_string_literal: true

module Interactors
  class CreateSplitTimesFromRawTimes
    include Interactors::Errors

    # TODO The parallel logic located in LiveTimeRowImporter#create_or_update_times should be centralized here.

    def self.perform!(args)
      new(args).perform!
    end

    def initialize(args)
      ArgsValidator.validate(params: args,
                             required: [:event_group, :raw_times],
                             exclusive: [:event_group, :raw_times],
                             class: self.class)
      @event_group = args[:event_group]
      @raw_times = args[:raw_times]
      @created_split_times = []
      @errors = []
      validate_setup
    end

    def perform!
      unless errors.present?
        creatable_split_times.each { |split_time| create_and_update_resources(split_time) }
        update_efforts_status
        send_notifications if event_group.permit_notifications?
      end
      Interactors::Response.new(errors, message)
    end

    private

    attr_reader :event_group, :raw_times, :created_split_times, :errors
    delegate :events, to: :event_group

    def create_and_update_resources(split_time)
      if split_time.save
        created_split_times << split_time
        raw_time = raw_times.find { |raw_time| raw_time.id == split_time.raw_time_id }
        raw_time.update(split_time: split_time) if raw_time
      else
        errors << resource_error_object(split_time)
      end
    end

    def update_efforts_status
      updated_efforts = Effort.where(id: created_split_times.map(&:effort_id).uniq).includes(split_times: :split)
      Interactors::UpdateEffortsStatus.perform!(updated_efforts)
    end

    def send_notifications
      notify_split_times = SplitTime.where(id: created_split_times.map(&:id)).includes(:effort).where.not(efforts: {person_id: nil})
      indexed_split_times = notify_split_times.group_by { |st| st.effort.person_id }
      indexed_split_times.each do |person_id, split_times|
        NotifyFollowersJob.perform_later(person_id: person_id, split_time_ids: split_times.map(&:id)) unless person_id.zero?
      end
    end

    def creatable_split_times
      creatable_effort_data_objects.flat_map(&:proposed_split_times).select(&:time_from_start)
    end

    def creatable_effort_data_objects
      @creatable_effort_data_objects ||= effort_data_objects.select { |effort_data| effort_data.clean? && effort_data.valid? }
    end

    def effort_data_objects
      events.map do |event|
        event_raw_times = grouped_raw_times[event.id]
        TimeRecordRowConverter.new(event: event, time_records: event_raw_times).effort_data_objects
      end.flatten
    end

    def grouped_raw_times
      RawTime.where(id: raw_times).with_relation_ids.group_by(&:event_id)
    end

    def message
      "Created #{created_split_times.size} new split times. " + failure_message
    end

    def failure_message
      errors.present? ? "Failed to create #{errors.size} split times. " : ''
    end

    def validate_setup
      errors << raw_time_mismatch_error unless raw_times.all? { |rt| rt.event_group_id == event_group.id }
    end
  end
end