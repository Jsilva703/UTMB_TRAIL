class RaceRoute < ApplicationRecord
  belongs_to :race
  has_many :route_points, dependent: :destroy

  validates :source_filename, presence: true
  validates :total_distance_m, numericality: { greater_than_or_equal_to: 0 }
  validates :points_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
