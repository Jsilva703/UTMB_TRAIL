module Api
  module V1
    module AthletePortal
      class SessionsController < ApplicationController
        def create
          tracking_session = TrackingSession
                             .includes(:athlete, :race)
                             .active
                             .find_by!(athlete_access_code: normalized_code)

          render json: session_payload(tracking_session)
        end

        private

        def normalized_code
          TrackingSession.normalize_athlete_access_code(params.require(:code))
        end

        def session_payload(tracking_session)
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
              started_at: tracking_session.started_at.iso8601,
              finished_at: tracking_session.finished_at&.iso8601
            },
            public_access: {
              code: tracking_session.public_access_code
            },
            server_credentials: {
              tracking_session_id: tracking_session.id,
              ingest_token: tracking_session.ingest_token
            }
          }
        end
      end
    end
  end
end
