class RoutePoint < ApplicationRecord
  belongs_to :race_route

  validates :sequence, :latitude, :longitude, :cumulative_distance_m, presence: true
  validates :sequence, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :sequence, uniqueness: { scope: :race_route_id }
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
  validates :cumulative_distance_m, numericality: { greater_than_or_equal_to: 0 }
end
