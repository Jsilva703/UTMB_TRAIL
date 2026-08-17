require "rails_helper"

RSpec.describe RaceRoutes::ImportGpx do
  it "imports track points preserving sequence and cumulative distance" do
    race = Race.create!(name: "Race", slug: "race", distance_km: 1)
    file = Rails.root.join("spec/fixtures/files/sample.gpx")

    result = described_class.new(race: race, file_path: file).call

    expect(result.race_route.points_count).to eq(3)
    expect(result.race_route.route_points.pluck(:sequence)).to eq([0, 1, 2])
    expect(result.race_route.route_points.first.cumulative_distance_m.to_f).to eq(0)
    expect(result.race_route.total_distance_m.to_f).to be > 0
  end

  it "rejects invalid XML without persisting a route" do
    race = Race.create!(name: "Race", slug: "race", distance_km: 1)
    file = Rails.root.join("spec/fixtures/files/invalid.gpx")

    expect { described_class.new(race: race, file_path: file).call }
      .to raise_error(Nokogiri::XML::SyntaxError)
    expect(race.reload.race_route).to be_nil
  end

  it "rejects GPX without track points" do
    race = Race.create!(name: "Race", slug: "race", distance_km: 1)
    file = Rails.root.join("spec/fixtures/files/empty.gpx")

    expect { described_class.new(race: race, file_path: file).call }
      .to raise_error(ArgumentError, /no track points/)
  end

  it "rejects invalid coordinates before insert_all bypasses model validations" do
    race = Race.create!(name: "Race", slug: "race", distance_km: 1)
    file = Rails.root.join("spec/fixtures/files/invalid_coordinates.gpx")

    expect { described_class.new(race: race, file_path: file).call }
      .to raise_error(ArgumentError, /invalid coordinates/)
    expect(RoutePoint.count).to eq(0)
  end

  it "rolls back the race route if point persistence fails" do
    race = Race.create!(name: "Race", slug: "race", distance_km: 1)
    file = Rails.root.join("spec/fixtures/files/sample.gpx")

    allow(RoutePoint).to receive(:insert_all!).and_raise(ActiveRecord::StatementInvalid, "boom")

    expect { described_class.new(race: race, file_path: file).call }
      .to raise_error(ActiveRecord::StatementInvalid)
    expect(race.reload.race_route).to be_nil
  end

  it "does not expand external XML entities" do
    race = Race.create!(name: "Race", slug: "race", distance_km: 1)
    file = Rails.root.join("spec/fixtures/files/external_entity.gpx")

    expect { described_class.new(race: race, file_path: file).call }
      .to raise_error(ArgumentError, /must not declare a DTD/)
    expect(race.reload.race_route).to be_nil
  end
end
