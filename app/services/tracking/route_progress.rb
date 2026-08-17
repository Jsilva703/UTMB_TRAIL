module Tracking
  class RouteProgress
    def initialize(tracking_session:, latitude:, longitude:)
      @tracking_session = tracking_session
      @latitude = latitude
      @longitude = longitude
    end

    def call
      race_route = tracking_session.race.race_route
      return nil if race_route.blank? || race_route.points_count.zero?

      nearest = NearestRoutePoint.new(race_route: race_route).call(
        latitude: latitude,
        longitude: longitude
      )
      return nil if nearest.blank?

      nearest_point = nearest.route_point
      return nil if nearest_point.blank?

      total_distance_m = race_route.total_distance_m.to_f
      estimated_distance_m = nearest_point.cumulative_distance_m.to_f
      remaining_distance_m = [total_distance_m - estimated_distance_m, 0].max

      {
        route_point_sequence: nearest_point.sequence,
        estimated_distance_m: estimated_distance_m.round(2),
        estimated_distance_km: (estimated_distance_m / 1000.0).round(2),
        estimated_progress_percentage: progress_percentage(estimated_distance_m, total_distance_m),
        estimated_remaining_distance_m: remaining_distance_m.round(2),
        estimated_remaining_distance_km: (remaining_distance_m / 1000.0).round(2),
        distance_from_route_m: nearest.distance_m.round(2)
      }
    end

    private

    attr_reader :tracking_session, :latitude, :longitude

    def progress_percentage(estimated_distance_m, total_distance_m)
      return 0.0 if total_distance_m.zero?

      ((estimated_distance_m / total_distance_m) * 100).round(1)
    end
  end
end
