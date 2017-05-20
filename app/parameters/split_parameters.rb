class SplitParameters < BaseParameters

  def self.permitted
    [:id, :course_id, :split_id, :distance_from_start, :distance_in_preferred_units, :vert_gain_from_start,
     :vert_gain_in_preferred_units, :vert_loss_from_start, :vert_loss_in_preferred_units, :kind, :base_name,
     :description, :sub_split_bitmap, :latitude, :longitude, :elevation, :elevation_as_entered,
     :name_extensions]
  end

  def self.csv_attributes
    %w(base_name distance_from_start kind vert_gain_from_start vert_loss_from_start latitude longitude elevation)
  end
end
