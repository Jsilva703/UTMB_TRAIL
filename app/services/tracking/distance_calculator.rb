module Tracking
  class DistanceCalculator
    Config = Struct.new(
      :excellent_accuracy_m,
      :acceptable_accuracy_m,
      :poor_accuracy_m,
      :very_poor_accuracy_m,
      :minimum_interval_s,
      :duplicate_distance_m,
      :noise_floor_m,
      :accuracy_noise_factor,
      :plausible_speed_mps,
      :impossible_speed_mps,
      :long_gap_s,
      keyword_init: true
    )

    Point = Struct.new(
      :source,
      :latitude,
      :longitude,
      :accuracy,
      :altitude,
      :recorded_at,
      :id,
      keyword_init: true
    )

    Result = Struct.new(
      :distance_m,
      :accepted_points,
      :rejected_points,
      :rejection_counts,
      keyword_init: true
    ) do
      def distance_km
        distance_m / 1000.0
      end

      def latest_valid_point
        accepted_points.last
      end

      def accepted_count
        accepted_points.size
      end

      def rejected_count
        rejected_points.size
      end
    end

    DEFAULT_CONFIG = Config.new(
      excellent_accuracy_m: 10.0,
      acceptable_accuracy_m: 50.0,
      poor_accuracy_m: 150.0,
      very_poor_accuracy_m: 250.0,
      minimum_interval_s: 0.5,
      duplicate_distance_m: 1.5,
      noise_floor_m: 1.5,
      accuracy_noise_factor: 0.05,
      plausible_speed_mps: 16.0,
      impossible_speed_mps: 35.0,
      long_gap_s: 45.0
    )

    def initialize(tracking_session: nil, location_points: nil, config: DEFAULT_CONFIG)
      @tracking_session = tracking_session
      @location_points = location_points
      @config = config
    end

    def call
      accepted_points = []
      rejected_points = []
      rejection_counts = Hash.new(0)
      distance_m = 0.0
      last_accepted = nil

      normalized_points.each do |point|
        reason = point_rejection_reason(point, last_accepted)

        if reason
          rejected_points << [point, reason]
          rejection_counts[reason] += 1
          next
        end

        distance_m += segment_distance(last_accepted, point) if last_accepted
        accepted_points << point
        last_accepted = point
      end

      log_rejection_summary(rejection_counts) if rejection_counts.any?

      Result.new(
        distance_m: distance_m.round(2),
        accepted_points: accepted_points,
        rejected_points: rejected_points,
        rejection_counts: rejection_counts.transform_keys(&:to_s)
      )
    end

    private

    attr_reader :tracking_session, :location_points, :config

    def normalized_points
      points = location_points || tracking_session.location_points
      points
        .sort_by { |point| [point.recorded_at || Time.zone.at(0), point.id || 0] }
        .map { |point| normalize(point) }
    end

    def normalize(point)
      Point.new(
        source: point,
        latitude: point.latitude.to_f,
        longitude: point.longitude.to_f,
        accuracy: point.accuracy&.to_f,
        altitude: point.altitude&.to_f,
        recorded_at: point.recorded_at,
        id: point.id
      )
    end

    def point_rejection_reason(point, previous)
      return :poor_accuracy if very_poor_accuracy?(point)
      return if previous.blank?

      delta_time_s = point.recorded_at.to_f - previous.recorded_at.to_f
      distance_m = distance_between(previous, point)

      return :duplicate if duplicate?(distance_m, delta_time_s)
      return :invalid_timestamp if delta_time_s <= config.minimum_interval_s
      return :noise if distance_m <= noise_floor(previous, point)

      speed_mps = distance_m / delta_time_s
      return :impossible_speed if speed_mps > config.impossible_speed_mps
      return :implausible_speed if speed_mps > config.plausible_speed_mps && delta_time_s < config.long_gap_s

      nil
    end

    def segment_distance(previous, point)
      distance_between(previous, point)
    end

    def duplicate?(distance_m, delta_time_s)
      delta_time_s <= 1.0 && distance_m <= config.duplicate_distance_m * 2
    end

    def noise_floor(previous, point)
      accuracy_floor = [previous.accuracy.to_f, point.accuracy.to_f].max * config.accuracy_noise_factor
      [config.noise_floor_m, accuracy_floor].max
    end

    def very_poor_accuracy?(point)
      point.accuracy.present? && point.accuracy > config.very_poor_accuracy_m
    end

    def distance_between(previous, point)
      Geo::Distance.haversine_m(
        previous.latitude,
        previous.longitude,
        point.latitude,
        point.longitude
      )
    end

    def log_rejection_summary(rejection_counts)
      Rails.logger.debug(
        "gps_filter tracking_session_id=#{tracking_session&.id || '-'} " \
        "rejections=#{rejection_counts.transform_keys(&:to_s).inspect}"
      )
    end
  end
end
