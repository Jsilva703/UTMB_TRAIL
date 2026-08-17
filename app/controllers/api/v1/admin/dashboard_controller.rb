module Api
  module V1
    module Admin
      class DashboardController < BaseController
        def show
          render json: {
            total_athletes: Athlete.count,
            athletes_tracking_now: Athlete.joins(:tracking_sessions).merge(TrackingSession.active).distinct.count,
            total_races: Race.count,
            races_with_route: Race.joins(:race_route).distinct.count,
            active_tracking_sessions: TrackingSession.active.count,
            finished_tracking_sessions: TrackingSession.where(status: "finished").count,
            races: race_summary
          }
        end

        private

        def race_summary
          Race.order(:name, :id).map do |race|
            {
              race_id: race.id,
              race_name: race.name,
              tracking_sessions_count: race.tracking_sessions.count,
              active_tracking_sessions_count: race.tracking_sessions.active.count
            }
          end
        end
      end
    end
  end
end
