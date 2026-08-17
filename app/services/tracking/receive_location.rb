module Tracking
  class ReceiveLocation
    Result = Struct.new(:location_point, :created, keyword_init: true)

    def initialize(tracking_session:, attributes:)
      @tracking_session = tracking_session
      @attributes = attributes
    end

    def call
      raise Forbidden, "tracking session is not active" unless tracking_session.active?

      normalized = normalize_attributes(attributes)
      existing = find_existing(normalized)
      return Result.new(location_point: existing, created: false) if existing

      Result.new(
        location_point: tracking_session.location_points.create!(normalized),
        created: true
      )
    rescue ActiveRecord::RecordNotUnique
      existing = find_existing(normalized)
      return Result.new(location_point: existing, created: false) if existing

      raise
    end

    private

    attr_reader :tracking_session, :attributes

    def find_existing(normalized)
      return if normalized[:client_point_id].blank?

      tracking_session.location_points.find_by(client_point_id: normalized[:client_point_id])
    end

    def normalize_attributes(attributes)
      {
        latitude: required_attribute(:latitude),
        longitude: required_attribute(:longitude),
        accuracy: attributes[:accuracy],
        altitude: attributes[:altitude],
        recorded_at: parse_time!(required_attribute(:recorded_at)),
        client_point_id: attributes[:client_point_id].presence
      }
    end

    def required_attribute(name)
      value = attributes[name]
      return value if value.present?

      location_point = LocationPoint.new
      location_point.errors.add(name, "can't be blank")
      raise ActiveRecord::RecordInvalid.new(location_point)
    end

    def parse_time!(value)
      value.is_a?(Time) || value.is_a?(ActiveSupport::TimeWithZone) ? value : Time.zone.iso8601(value.to_s)
    rescue ArgumentError
      location_point = LocationPoint.new
      location_point.errors.add(:recorded_at, "is invalid")
      raise ActiveRecord::RecordInvalid.new(location_point)
    end
  end
end
