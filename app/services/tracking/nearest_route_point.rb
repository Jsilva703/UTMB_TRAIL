module Tracking
  class NearestRoutePoint
    Result = Struct.new(:route_point, :distance_m, keyword_init: true)

    # MVP strategy: O(n) scan over normalized GPX points for one race route.
    # This is correct and simple for thousands of points; PostGIS can replace
    # this class later if route volume or request rate requires spatial indexes.
    def initialize(race_route:)
      @race_route = race_route
    end

    def call(latitude:, longitude:)
      nearest_point = nil
      nearest_distance_m = nil

      race_route.route_points.select(:id, :sequence, :latitude, :longitude, :cumulative_distance_m).find_each do |point|
        distance_m = Geo::Distance.haversine_m(latitude, longitude, point.latitude, point.longitude)
        next if nearest_distance_m && distance_m >= nearest_distance_m

        nearest_point = point
        nearest_distance_m = distance_m
      end

      Result.new(route_point: nearest_point, distance_m: nearest_distance_m) if nearest_point
    end

    private

    attr_reader :race_route
  end
end
