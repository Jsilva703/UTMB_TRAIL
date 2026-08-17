require "nokogiri"

module RaceRoutes
  class ImportGpx
    Result = Struct.new(:race_route, keyword_init: true)

    def initialize(race:, file_path:)
      @race = race
      @file_path = Pathname.new(file_path)
    end

    def call
      raise ArgumentError, "GPX file not found: #{file_path}" unless file_path.exist?
      raise ArgumentError, "Race already has an imported route" if race.race_route.present?

      points = parse_points
      raise ArgumentError, "GPX file has no track points" if points.empty?

      ActiveRecord::Base.transaction do
        rows = route_point_rows(points)
        race_route = race.create_race_route!(
          source_filename: file_path.basename.to_s,
          total_distance_m: rows.last[:cumulative_distance_m],
          points_count: points.size
        )

        RoutePoint.insert_all!(rows.map { |row| row.merge(race_route_id: race_route.id) })
        race_route.reload
        Rails.logger.info("GPX imported race_id=#{race.id} race_route_id=#{race_route.id} points=#{points.size}")

        Result.new(race_route: race_route)
      end
    rescue StandardError => e
      Rails.logger.error("GPX import failed race_id=#{race.id} file=#{file_path}: #{e.class} #{e.message}")
      raise
    end

    private

    attr_reader :race, :file_path

    def parse_points
      doc = Nokogiri::XML(file_path.read) { |config| config.strict.nonet.noblanks }
      raise ArgumentError, "GPX file must not declare a DTD" if doc.internal_subset || doc.external_subset

      nodes = doc.xpath("//*[local-name()='trkpt']")

      nodes.map.with_index do |node, index|
        point = {
          latitude: BigDecimal(node["lat"]),
          longitude: BigDecimal(node["lon"]),
          altitude: altitude_from(node)
        }
        validate_point!(point, index)
        point
      end
    end

    def validate_point!(point, index)
      latitude = point[:latitude]
      longitude = point[:longitude]
      return if latitude.between?(-90, 90) && longitude.between?(-180, 180)

      raise ArgumentError, "GPX track point #{index} has invalid coordinates"
    end

    def altitude_from(node)
      elevation = node.at_xpath("*[local-name()='ele']")
      elevation&.text&.strip&.presence&.then { |value| BigDecimal(value) }
    end

    def route_point_rows(points)
      cumulative_distance_m = 0.0
      now = Time.current

      points.each_with_index.map do |point, index|
        if index.positive?
          previous = points[index - 1]
          cumulative_distance_m += Geo::Distance.haversine_m(
            previous[:latitude],
            previous[:longitude],
            point[:latitude],
            point[:longitude]
          )
        end

        {
          sequence: index,
          latitude: point[:latitude],
          longitude: point[:longitude],
          altitude: point[:altitude],
          cumulative_distance_m: cumulative_distance_m,
          created_at: now,
          updated_at: now
        }
      end
    end

  end
end
