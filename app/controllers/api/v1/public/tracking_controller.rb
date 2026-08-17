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
          scope = @tracking_session.location_points.order(recorded_at: :asc, id: :asc)
          points = scope.offset((page - 1) * per_page).limit(per_page)

          render json: {
            locations: points.map { |point| public_location_payload(point) },
            pagination: {
              page: page,
              per_page: per_page,
              total_count: scope.count
            }
          }
        end

        private

        def set_tracking_session
          @tracking_session = TrackingSession.includes(:athlete, :race).find_by!(public_token: params[:public_token])
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
