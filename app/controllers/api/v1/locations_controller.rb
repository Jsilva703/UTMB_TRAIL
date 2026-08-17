module Api
  module V1
    class LocationsController < ApplicationController
      before_action :set_tracking_session
      before_action :authenticate_ingest_token!

      def create
        result = Tracking::ReceiveLocation.new(
          tracking_session: @tracking_session,
          attributes: location_params.to_h.symbolize_keys
        ).call

        render json: location_payload(result.location_point).merge(created: result.created),
               status: result.created ? :created : :ok
      end

      def batch
        result = Tracking::ReceiveLocationBatch.new(
          tracking_session: @tracking_session,
          locations: batch_locations_params
        ).call

        render json: {
          created_count: result.created_count,
          duplicate_count: result.duplicate_count,
          locations: result.location_points.map { |point| location_payload(point) }
        }, status: :created
      end

      private

      def set_tracking_session
        @tracking_session = TrackingSession.find(params[:tracking_session_id])
      end

      def authenticate_ingest_token!
        token = bearer_token.to_s
        return if token.present? &&
                  token.bytesize == @tracking_session.ingest_token.bytesize &&
                  ActiveSupport::SecurityUtils.secure_compare(@tracking_session.ingest_token, token)

        Rails.logger.warn("invalid ingest attempt tracking_session_id=#{@tracking_session.id}")
        render json: { error: "invalid ingest token" }, status: :unauthorized
      end

      def location_params
        params.permit(:latitude, :longitude, :accuracy, :altitude, :recorded_at, :client_point_id)
      end

      def batch_locations_params
        params.require(:locations).map do |location|
          location.permit(:latitude, :longitude, :accuracy, :altitude, :recorded_at, :client_point_id)
        end
      end

      def location_payload(location_point)
        {
          id: location_point.id,
          latitude: location_point.latitude.to_f,
          longitude: location_point.longitude.to_f,
          accuracy: location_point.accuracy&.to_f,
          altitude: location_point.altitude&.to_f,
          recorded_at: location_point.recorded_at.iso8601,
          client_point_id: location_point.client_point_id
        }
      end
    end
  end
end
