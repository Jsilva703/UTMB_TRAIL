class AdminTrackingSessionSerializer
  def initialize(tracking_session)
    @tracking_session = tracking_session
  end

  def as_json(*)
    {
      id: tracking_session.id,
      status: tracking_session.status,
      public_token: tracking_session.public_token,
      ingest_token: tracking_session.ingest_token,
      started_at: tracking_session.started_at.iso8601,
      finished_at: tracking_session.finished_at&.iso8601,
      athlete: {
        id: tracking_session.athlete.id,
        name: tracking_session.athlete.name
      },
      race: {
        id: tracking_session.race.id,
        name: tracking_session.race.name,
        distance_km: tracking_session.race.distance_km.to_f
      },
      latest_location: latest_location_payload
    }
  end

  private

  attr_reader :tracking_session

  def latest_location_payload
    location = tracking_session.latest_location
    return nil unless location

    {
      latitude: location.latitude.to_f,
      longitude: location.longitude.to_f,
      accuracy: location.accuracy&.to_f,
      altitude: location.altitude&.to_f,
      recorded_at: location.recorded_at.iso8601
    }
  end
end
