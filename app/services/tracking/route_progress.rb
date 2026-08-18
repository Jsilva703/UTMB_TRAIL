module Tracking
  class RouteProgress
    def initialize(tracking_session:, latitude: nil, longitude: nil, distance_result: nil)
      @tracking_session = tracking_session
      @latitude = latitude
      @longitude = longitude
      @distance_result = distance_result
    end

    def call
      race_route = tracking_session.race.race_route
      return nil if race_route.blank? || race_route.points_count.zero?

      match = RouteMapMatcher.new(race_route: race_route).call(
        location_points: matchable_points
      )
      return nil if match.blank?

      matched_point = match.route_point
      return nil if matched_point.blank?

      total_distance_m = race_route.total_distance_m.to_f
      route_progress_m = matched_point.cumulative_distance_m.to_f
      remaining_distance_m = [total_distance_m - route_progress_m, 0].max

      {
        route_point_sequence: matched_point.sequence,
        route_progress_m: route_progress_m.round(2),
        route_progress_km: (route_progress_m / 1000.0).round(2),
        estimated_distance_m: route_progress_m.round(2),
        estimated_distance_km: (route_progress_m / 1000.0).round(2),
        estimated_progress_percentage: progress_percentage(route_progress_m, total_distance_m),
        estimated_remaining_distance_m: remaining_distance_m.round(2),
        estimated_remaining_distance_km: (remaining_distance_m / 1000.0).round(2),
        distance_from_route_m: match.distance_m.round(2)
      }
    end

    private

    attr_reader :tracking_session, :latitude, :longitude, :distance_result

    def matchable_points
      accepted = distance_result&.accepted_points
      return accepted if accepted.present?
      return direct_location_point if latitude.present? && longitude.present?

      DistanceCalculator.new(tracking_session: tracking_session).call.accepted_points
    end

    def direct_location_point
      [
        DistanceCalculator::Point.new(
          latitude: latitude.to_f,
          longitude: longitude.to_f,
          accuracy: nil,
          altitude: nil,
          recorded_at: Time.current
        )
      ]
    end

    def progress_percentage(estimated_distance_m, total_distance_m)
      return 0.0 if total_distance_m.zero?

      ((estimated_distance_m / total_distance_m) * 100).round(1)
    end
  end
end
