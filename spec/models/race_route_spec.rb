require 'rails_helper'

RSpec.describe RaceRoute, type: :model do
  it "belongs to one race and validates counters" do
    race = Race.create!(name: "Race", slug: "race", distance_km: 10)
    route = described_class.new(race: race, source_filename: "sample.gpx", total_distance_m: 1000, points_count: 2)

    expect(route).to be_valid
  end
end
