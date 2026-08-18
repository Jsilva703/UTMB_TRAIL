module Api
  module V1
    module Public
      class TrackingController < ApplicationController
        before_action :set_tracking_session

        def show
          render json: PublicTrackingSerializer.new(@tracking_session).as_json
        end

        def locations
          per_page = [[params.fetch(:per_page, 50).to_i, 1].max, 100].min
          page = [params.fetch(:page, 1).to_i, 1].max
          points = Tracking::DistanceCalculator.new(tracking_session: @tracking_session).call.accepted_points
          page_points = points.slice((page - 1) * per_page, per_page) || []

          render json: {
            locations: page_points.map { |point| public_location_payload(point) },
            pagination: {
              page: page,
              per_page: per_page,
              total_count: points.size
            }
          }
        end

        def route
          render json: PublicRaceRouteSerializer.new(@tracking_session.race.race_route).as_json
        end

        private

        def set_tracking_session
          @tracking_session = TrackingSession
                              .includes(:athlete, :race)
                              .find_by!(public_lookup_param => public_lookup_value)
        end

        def public_lookup_param
          params[:public_access_code].present? ? :public_access_code : :public_token
        end

        def public_lookup_value
          return TrackingSession.normalize_public_access_code(params[:public_access_code]) if params[:public_access_code].present?

          params[:public_token]
        end

        def public_location_payload(location_point)
          {
            latitude: location_point.latitude.to_f,
            longitude: location_point.longitude.to_f,
            accuracy: location_point.accuracy&.to_f,
            altitude: location_point.altitude&.to_f,
            recorded_at: location_point.recorded_at.iso8601
          }
        end
      end
    end
  end
end
