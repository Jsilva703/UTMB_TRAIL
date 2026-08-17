module Geo
  class Distance
    EARTH_RADIUS_M = 6_371_000.0

    def self.haversine_m(lat1, lon1, lat2, lon2)
      latitude_1 = to_radians(lat1.to_f)
      latitude_2 = to_radians(lat2.to_f)
      delta_latitude = to_radians(lat2.to_f - lat1.to_f)
      delta_longitude = to_radians(lon2.to_f - lon1.to_f)

      a = Math.sin(delta_latitude / 2)**2 +
          Math.cos(latitude_1) * Math.cos(latitude_2) *
          Math.sin(delta_longitude / 2)**2

      EARTH_RADIUS_M * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    end

    def self.to_radians(value)
      value * Math::PI / 180
    end
    private_class_method :to_radians
  end
end
