module Tracking
  class RouteMapMatcher
    Config = Struct.new(
      :backward_tolerance_m,
      :minimum_forward_window_m,
      :forward_speed_mps,
      :forward_buffer_m,
      :regression_tolerance_m,
      keyword_init: true
    )

    Match = Struct.new(:route_point, :distance_m, keyword_init: true)

    DEFAULT_CONFIG = Config.new(
      backward_tolerance_m: 35.0,
      minimum_forward_window_m: 180.0,
      forward_speed_mps: 8.0,
      forward_buffer_m: 80.0,
      regression_tolerance_m: 35.0
    )

    def initialize(race_route:, route_points: nil, config: DEFAULT_CONFIG)
      @race_route = race_route
      @route_points = route_points
      @config = config
    end

    def call(location_points:)
      return nil if location_points.blank?

      last_match = nil
      previous_location = nil

      location_points.each do |location|
        match = match_location(location, previous_location, last_match)
        last_match = monotonic_match(match, last_match)
        previous_location = location
      end

      last_match
    end

    private

    attr_reader :race_route, :route_points, :config

    def match_location(location, previous_location, previous_match)
      candidates = candidate_route_points(previous_location, previous_match, location)
      nearest = candidates.min_by do |point|
        Geo::Distance.haversine_m(location.latitude, location.longitude, point.latitude, point.longitude)
      end

      return if nearest.blank?

      Match.new(
        route_point: nearest,
        distance_m: Geo::Distance.haversine_m(
          location.latitude,
          location.longitude,
          nearest.latitude,
          nearest.longitude
        )
      )
    end

    def candidate_route_points(previous_location, previous_match, current_location)
      return ordered_route_points if previous_match.blank? || previous_location.blank?

      previous_distance_m = previous_match.route_point.cumulative_distance_m.to_f
      delta_time_s = [current_location.recorded_at.to_f - previous_location.recorded_at.to_f, 0].max
      forward_window_m = [
        config.minimum_forward_window_m,
        (delta_time_s * config.forward_speed_mps) + config.forward_buffer_m
      ].max

      min_distance_m = [previous_distance_m - config.backward_tolerance_m, 0].max
      max_distance_m = previous_distance_m + forward_window_m

      window = ordered_route_points[window_start_index(min_distance_m)...window_end_index(max_distance_m)]

      window.presence || ordered_route_points
    end

    def monotonic_match(match, previous_match)
      return previous_match if match.blank?
      return match if previous_match.blank?

      previous_distance_m = previous_match.route_point.cumulative_distance_m.to_f
      current_distance_m = match.route_point.cumulative_distance_m.to_f

      return previous_match if current_distance_m < previous_distance_m - config.regression_tolerance_m

      match
    end

    def ordered_route_points
      @ordered_route_points ||= Array(route_points || race_route.route_points.order(:sequence).to_a)
    end

    def window_start_index(min_distance_m)
      ordered_route_points.bsearch_index do |point|
        point.cumulative_distance_m.to_f >= min_distance_m
      end || ordered_route_points.size
    end

    def window_end_index(max_distance_m)
      ordered_route_points.bsearch_index do |point|
        point.cumulative_distance_m.to_f > max_distance_m
      end || ordered_route_points.size
    end
  end
end
