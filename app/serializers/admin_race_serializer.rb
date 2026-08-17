class AdminRaceSerializer
  def initialize(race)
    @race = race
  end

  def as_json(*)
    race_route = race.race_route

    {
      id: race.id,
      name: race.name,
      slug: race.slug,
      distance_km: race.distance_km.to_f,
      status: race.status,
      published: race.status == "active",
      has_route: race_route.present?,
      route_points_count: race_route&.points_count || 0,
      tracking_sessions_count: race.tracking_sessions.count,
      active_tracking_sessions_count: race.tracking_sessions.active.count
    }
  end

  private

  attr_reader :race
end
