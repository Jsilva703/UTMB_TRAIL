class PublicRaceRouteSerializer
  def initialize(race_route)
    @race_route = race_route
  end

  def as_json(*)
    return { route: nil } if race_route.blank?

    {
      route: {
        source_filename: race_route.source_filename,
        total_distance_m: race_route.total_distance_m.to_f,
        points_count: race_route.points_count,
        points: race_route.route_points.order(:sequence).map { |point| point_payload(point) }
      }
    }
  end

  private

  attr_reader :race_route

  def point_payload(point)
    {
      sequence: point.sequence,
      latitude: point.latitude.to_f,
      longitude: point.longitude.to_f,
      altitude: point.altitude&.to_f,
      cumulative_distance_m: point.cumulative_distance_m.to_f
    }
  end
end
