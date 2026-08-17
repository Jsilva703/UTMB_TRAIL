module Api
  module V1
    module Admin
      class TrackingSessionsController < BaseController
        def index
          tracking_sessions = filtered_tracking_sessions
                              .includes(:athlete, :race)
                              .order(started_at: :desc, id: :desc)

          render json: {
            tracking_sessions: tracking_sessions.map { |session| AdminTrackingSessionSerializer.new(session).as_json }
          }
        end

        def show
          tracking_session = TrackingSession.includes(:athlete, :race).find(params[:id])
          render json: { tracking_session: AdminTrackingSessionSerializer.new(tracking_session).as_json }
        end

        def create
          athlete = Athlete.find(tracking_session_params.fetch(:athlete_id))
          race = Race.find(tracking_session_params.fetch(:race_id))
          tracking_session = TrackingSession.create!(athlete: athlete, race: race)

          render json: {
            tracking_session: AdminTrackingSessionSerializer.new(tracking_session).as_json
          }, status: :created
        end

        private

        def filtered_tracking_sessions
          scope = TrackingSession.all
          scope = scope.active if ActiveModel::Type::Boolean.new.cast(params[:active])
          scope = scope.where(status: "finished") if ActiveModel::Type::Boolean.new.cast(params[:finished])
          scope = scope.where(race_id: params[:race_id]) if params[:race_id].present?
          scope = scope.where(athlete_id: params[:athlete_id]) if params[:athlete_id].present?
          scope
        end

        def tracking_session_params
          params.permit(:athlete_id, :race_id)
        end
      end
    end
  end
end
