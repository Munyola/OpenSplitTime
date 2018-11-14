# frozen_string_literal: true

class EffortRow < SimpleDelegator
  ULTRASIGNUP_STATUS_TABLE = {'Finished' => 1, 'Dropped' => 2, 'Not Started' => 3}

  def display_overall_rank
    started? ? overall_rank : '--'
  end

  def display_gender_rank
    started? ? gender_rank : '--'
  end

  def final_lap_split_name
    multiple_laps? ? "#{final_split_name} Lap #{final_lap}" : final_split_name
  end

  def final_day_and_time
    final_absolute_time.in_time_zone(event_home_zone)
  end

  def year_and_lap
    multiple_laps? ? "#{start_time.year} / Lap #{lap}" : "#{start_time.year}"
  end

  def run_status
    case
    when finished?
      'Finished'
    when dropped?
      'Dropped'
    when in_progress?
      'In Progress'
    else
      'Not Started'
    end
  end

  def ultrasignup_finish_status
    ULTRASIGNUP_STATUS_TABLE[run_status] || "#{name} (id: #{id}, bib: #{bib_number}) is in progress"
  end
end
