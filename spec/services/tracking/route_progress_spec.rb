require "rails_helper"

RSpec.describe Tracking::RouteProgress do
  it "finds the nearest route point and estimates progress" do
    athlete = Athlete.create!(name: "Runner")
    race = Race.create!(name: "Race", slug: "race", distance_km: 10)
    route = RaceRoute.create!(race: race, source_filename: "sample.gpx", total_distance_m: 1000, points_count: 3)
    RoutePoint.create!(race_route: route, sequence: 0, latitude: 0, longitude: 0, cumulative_distance_m: 0)
    RoutePoint.create!(race_route: route, sequence: 1, latitude: 0, longitude: 0.005, cumulative_distance_m: 500)
    RoutePoint.create!(race_route: route, sequence: 2, latitude: 0, longitude: 0.01, cumulative_distance_m: 1000)
    session = TrackingSession.create!(athlete: athlete, race: race)

    progress = described_class.new(tracking_session: session, latitude: 0, longitude: 0.0048).call

    expect(progress[:route_point_sequence]).to eq(1)
    expect(progress[:estimated_progress_percentage]).to eq(50.0)
    expect(progress[:estimated_remaining_distance_m]).to eq(500.0)
    expect(progress[:distance_from_route_m]).to be < 30
  end

  it "exposes distance from route for far away locations" do
    athlete = Athlete.create!(name: "Runner")
    race = Race.create!(name: "Race", slug: "race", distance_km: 10)
    route = RaceRoute.create!(race: race, source_filename: "sample.gpx", total_distance_m: 1000, points_count: 1)
    RoutePoint.create!(race_route: route, sequence: 0, latitude: 0, longitude: 0, cumulative_distance_m: 0)
    session = TrackingSession.create!(athlete: athlete, race: race)

    progress = described_class.new(tracking_session: session, latitude: 1, longitude: 1).call

    expect(progress[:distance_from_route_m]).to be > 100_000
  end

  it "returns nil when the race has no imported route" do
    athlete = Athlete.create!(name: "Runner")
    race = Race.create!(name: "Race", slug: "race", distance_km: 10)
    session = TrackingSession.create!(athlete: athlete, race: race)

    expect(described_class.new(tracking_session: session, latitude: 0, longitude: 0).call).to be_nil
  end
end
