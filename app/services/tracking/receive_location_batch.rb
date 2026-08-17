module Tracking
  class ReceiveLocationBatch
    Result = Struct.new(:created_count, :duplicate_count, :location_points, keyword_init: true)

    def initialize(tracking_session:, locations:)
      @tracking_session = tracking_session
      @locations = Array(locations)
    end

    def call
      Rails.logger.info("location batch received tracking_session_id=#{tracking_session.id} count=#{locations.size}")

      created_count = 0
      duplicate_count = 0
      points = []

      ActiveRecord::Base.transaction do
        locations.each do |attributes|
          result = ReceiveLocation.new(
            tracking_session: tracking_session,
            attributes: attributes.to_h.symbolize_keys
          ).call

          result.created ? created_count += 1 : duplicate_count += 1
          points << result.location_point
        end
      end

      Result.new(created_count: created_count, duplicate_count: duplicate_count, location_points: points)
    end

    private

    attr_reader :tracking_session, :locations
  end
end
