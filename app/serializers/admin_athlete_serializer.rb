class AdminAthleteSerializer
  def initialize(athlete)
    @athlete = athlete
  end

  def as_json(*)
    active_session = athlete.tracking_sessions.active.order(started_at: :desc, id: :desc).first

    {
      id: athlete.id,
      name: athlete.name,
      status: athlete.status,
      has_active_tracking: active_session.present?,
      active_tracking_session: active_session && {
        id: active_session.id,
        race_id: active_session.race_id,
        public_token: active_session.public_token,
        started_at: active_session.started_at.iso8601
      }
    }
  end

  private

  attr_reader :athlete
end
