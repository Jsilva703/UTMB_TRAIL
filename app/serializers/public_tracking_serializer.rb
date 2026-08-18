class PublicTrackingSerializer
  def initialize(tracking_session)
    @tracking_session = tracking_session
  end

  def as_json(*)
    {
      athlete: {
        name: tracking_session.athlete.name
      },
      race: {
        name: tracking_session.race.name,
        distance_km: tracking_session.race.distance_km.to_f
      },
      tracking: {
        status: tracking_session.status,
        started_at: tracking_session.started_at&.iso8601,
        last_update_at: latest_valid_location&.recorded_at&.iso8601
      },
      location: location_payload,
      distance_traveled: distance_traveled_payload,
      route_progress: route_progress
    }
  end

  private

  attr_reader :tracking_session

  def distance_result
    @distance_result ||= Tracking::DistanceCalculator.new(tracking_session: tracking_session).call
  end

  def latest_valid_location
    @latest_valid_location ||= distance_result.latest_valid_point
  end

  def location_payload
    return nil if latest_valid_location.blank?

    {
      latitude: latest_valid_location.latitude.to_f,
      longitude: latest_valid_location.longitude.to_f,
      accuracy: latest_valid_location.accuracy&.to_f
    }
  end

  def distance_traveled_payload
    {
      estimated_distance_m: distance_result.distance_m.round(2),
      estimated_distance_km: distance_result.distance_km.round(2),
      accepted_points_count: distance_result.accepted_count,
      rejected_points_count: distance_result.rejected_count
    }
  end

  def route_progress
    return nil if latest_valid_location.blank?

    Tracking::RouteProgress.new(
      tracking_session: tracking_session,
      distance_result: distance_result
    ).call
  end
end
