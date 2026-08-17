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
        last_update_at: latest_location&.recorded_at&.iso8601
      },
      location: location_payload,
      route_progress: route_progress
    }
  end

  private

  attr_reader :tracking_session

  def latest_location
    @latest_location ||= tracking_session.latest_location
  end

  def location_payload
    return nil if latest_location.blank?

    {
      latitude: latest_location.latitude.to_f,
      longitude: latest_location.longitude.to_f,
      accuracy: latest_location.accuracy&.to_f
    }
  end

  def route_progress
    return nil if latest_location.blank?

    Tracking::RouteProgress.new(
      tracking_session: tracking_session,
      latitude: latest_location.latitude,
      longitude: latest_location.longitude
    ).call
  end
end
