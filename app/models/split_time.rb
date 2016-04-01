class SplitTime < ActiveRecord::Base
  enum data_status: [:bad, :questionable, :good]   # nil = unknown, 0 = bad, 1 = questionable, 2 = good
  belongs_to :effort
  belongs_to :split

  validates_presence_of :effort_id, :split_id, :time_from_start
  validates :data_status, inclusion: { in: SplitTime.data_statuses.keys }, allow_nil: true
  validates_uniqueness_of :split_id, scope: :effort_id,
                          :message => "only one of any given split permitted within an effort"
  validates_numericality_of :time_from_start, equal_to: 0, :if => 'split_is_start?',
                            :message => "for the starting split_time must be 0"
  validate :course_is_consistent, unless: 'effort.nil? | split.nil?'   # TODO fix tests so that .nil? checks are not necessary

  def split_is_start?
    split.try(:kind) == "start"
  end

  def course_is_consistent
    if effort.event.course_id != split.course_id
      errors.add(:effort_id, "the effort.event.course_id does not resolve with the split.course_id")
      errors.add(:split_id, "the effort.event.course_id does not resolve with the split.course_id")
    end
  end

  def formatted_time
    seconds = time_from_start % 60
    minutes = (time_from_start / 60) % 60
    hours = time_from_start / (60 * 60)

    format("%02d:%02d:%02d", hours, minutes, seconds)
  end

end
