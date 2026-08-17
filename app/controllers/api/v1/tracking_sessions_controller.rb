module Api
  module V1
    class TrackingSessionsController < ApplicationController
      before_action :set_tracking_session, only: :finish
      before_action :authenticate_ingest_token!, only: :finish

      def create
        athlete = Athlete.find(tracking_session_params.fetch(:athlete_id))
        race = Race.find(tracking_session_params.fetch(:race_id))
        tracking_session = TrackingSession.create!(athlete: athlete, race: race)

        Rails.logger.info("tracking session created id=#{tracking_session.id} athlete_id=#{athlete.id} race_id=#{race.id}")

        render json: tracking_session_payload(tracking_session), status: :created
      end

      def finish
        @tracking_session.finish!
        Rails.logger.info("tracking session finished id=#{@tracking_session.id}")

        render json: {
          tracking: {
            status: @tracking_session.status,
            finished_at: @tracking_session.finished_at&.iso8601
          }
        }
      end

      private

      def tracking_session_params
        params.permit(:athlete_id, :race_id)
      end

      def set_tracking_session
        @tracking_session = TrackingSession.find(params[:id])
      end

      def authenticate_ingest_token!
        token = bearer_token.to_s
        return if token.present? &&
                  token.bytesize == @tracking_session.ingest_token.bytesize &&
                  ActiveSupport::SecurityUtils.secure_compare(@tracking_session.ingest_token, token)

        Rails.logger.warn("invalid ingest attempt tracking_session_id=#{@tracking_session.id}")
        render json: { error: "invalid ingest token" }, status: :unauthorized
      end

      def tracking_session_payload(tracking_session)
        {
          id: tracking_session.id,
          athlete_id: tracking_session.athlete_id,
          race_id: tracking_session.race_id,
          status: tracking_session.status,
          public_token: tracking_session.public_token,
          ingest_token: tracking_session.ingest_token,
          started_at: tracking_session.started_at.iso8601
        }
      end
    end
  end
end
