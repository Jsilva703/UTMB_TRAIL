require 'rails_helper'

RSpec.describe RoutePoint, type: :model do
  it "preserves sequence uniquely inside a route" do
    race = Race.create!(name: "Race", slug: "race", distance_km: 10)
    route = RaceRoute.create!(race: race, source_filename: "sample.gpx", total_distance_m: 1000, points_count: 1)
    described_class.create!(race_route: route, sequence: 0, latitude: 0, longitude: 0, cumulative_distance_m: 0)

    duplicate = described_class.new(race_route: route, sequence: 0, latitude: 1, longitude: 1, cumulative_distance_m: 10)

    expect(duplicate).not_to be_valid
  end
end
