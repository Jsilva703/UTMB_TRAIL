require "rails_helper"

RSpec.describe Tracking::DistanceCalculator do
  Point = Struct.new(:id, :latitude, :longitude, :accuracy, :altitude, :recorded_at, keyword_init: true)

  def point(latitude:, longitude:, at:, accuracy: 8, id: nil)
    Point.new(
      id: id,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      altitude: nil,
      recorded_at: Time.zone.parse(at)
    )
  end

  def distance_for(points)
    described_class.new(location_points: points).call
  end

  it "accumulates normal movement" do
    result = distance_for([
      point(latitude: 0, longitude: 0, at: "2026-08-17 10:00:00", id: 1),
      point(latitude: 0, longitude: 0.001, at: "2026-08-17 10:00:30", id: 2),
      point(latitude: 0, longitude: 0.002, at: "2026-08-17 10:01:00", id: 3)
    ])

    expect(result.distance_m).to be_between(220, 224)
    expect(result.accepted_count).to eq(3)
  end

  it "does not count GPS drift while the athlete is effectively stopped" do
    result = distance_for([
      point(latitude: 0, longitude: 0, at: "2026-08-17 10:00:00", id: 1),
      point(latitude: 0, longitude: 0.000005, at: "2026-08-17 10:00:10", id: 2),
      point(latitude: 0, longitude: 0.000008, at: "2026-08-17 10:00:20", id: 3)
    ])

    expect(result.distance_m).to eq(0.0)
    expect(result.rejection_counts["noise"]).to eq(2)
  end

  it "rejects points with extremely poor accuracy" do
    result = distance_for([
      point(latitude: 0, longitude: 0, at: "2026-08-17 10:00:00", id: 1),
      point(latitude: 0, longitude: 0.001, at: "2026-08-17 10:00:30", accuracy: 300, id: 2)
    ])

    expect(result.distance_m).to eq(0.0)
    expect(result.rejection_counts["poor_accuracy"]).to eq(1)
  end

  it "rejects impossible geographic jumps" do
    result = distance_for([
      point(latitude: 0, longitude: 0, at: "2026-08-17 10:00:00", id: 1),
      point(latitude: 0, longitude: 0.01, at: "2026-08-17 10:00:01", id: 2)
    ])

    expect(result.distance_m).to eq(0.0)
    expect(result.rejection_counts["impossible_speed"]).to eq(1)
  end

  it "rejects timestamps that are equal or too close" do
    result = distance_for([
      point(latitude: 0, longitude: 0, at: "2026-08-17 10:00:00", id: 1),
      point(latitude: 0, longitude: 0.001, at: "2026-08-17 10:00:00", id: 2)
    ])

    expect(result.distance_m).to eq(0.0)
    expect(result.rejection_counts["invalid_timestamp"]).to eq(1)
  end

  it "orders points by recorded_at instead of received order" do
    result = distance_for([
      point(latitude: 0, longitude: 0.002, at: "2026-08-17 10:01:00", id: 3),
      point(latitude: 0, longitude: 0, at: "2026-08-17 10:00:00", id: 1),
      point(latitude: 0, longitude: 0.001, at: "2026-08-17 10:00:30", id: 2)
    ])

    expect(result.distance_m).to be_between(220, 224)
    expect(result.accepted_points.map(&:id)).to eq([1, 2, 3])
  end

  it "handles delayed batch points by rebuilding the timeline" do
    result = distance_for([
      point(latitude: 0, longitude: 0.003, at: "2026-08-17 10:01:30", id: 4),
      point(latitude: 0, longitude: 0.001, at: "2026-08-17 10:00:30", id: 2),
      point(latitude: 0, longitude: 0.002, at: "2026-08-17 10:01:00", id: 3),
      point(latitude: 0, longitude: 0, at: "2026-08-17 10:00:00", id: 1)
    ])

    expect(result.distance_m).to be_between(332, 335)
    expect(result.accepted_points.map(&:id)).to eq([1, 2, 3, 4])
  end

  it "accepts plausible movement after a sampling gap" do
    result = distance_for([
      point(latitude: 0, longitude: 0, at: "2026-08-17 10:00:00", id: 1),
      point(latitude: 0, longitude: 0.006, at: "2026-08-17 10:02:00", id: 2)
    ])

    expect(result.distance_m).to be_between(660, 670)
    expect(result.rejected_count).to eq(0)
  end

  it "returns zero distance for a session without points" do
    result = distance_for([])

    expect(result.distance_m).to eq(0.0)
    expect(result.latest_valid_point).to be_nil
  end

  it "returns zero distance for a single valid point" do
    result = distance_for([
      point(latitude: 0, longitude: 0, at: "2026-08-17 10:00:00", id: 1)
    ])

    expect(result.distance_m).to eq(0.0)
    expect(result.accepted_count).to eq(1)
  end

  it "preserves representative session 8 regressions without storing the full dataset" do
    result = distance_for([
      point(latitude: -23.524346, longitude: -46.885805, at: "2026-08-17 13:00:00", id: 1),
      point(latitude: -23.524346, longitude: -46.885805, at: "2026-08-17 13:00:00", id: 2),
      point(latitude: -23.524, longitude: -46.884, at: "2026-08-17 13:00:01", id: 3),
      point(latitude: -23.52425, longitude: -46.8858, at: "2026-08-17 13:00:35", accuracy: 360, id: 4),
      point(latitude: -23.5242, longitude: -46.8857, at: "2026-08-17 13:00:45", id: 5)
    ])

    expect(result.rejection_counts).to include(
      "duplicate" => 1,
      "impossible_speed" => 1,
      "poor_accuracy" => 1
    )
    expect(result.accepted_points.map(&:id)).to eq([1, 5])
  end
end
