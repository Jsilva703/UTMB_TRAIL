require "rails_helper"

RSpec.describe Geo::Distance do
  it "calculates haversine distance in meters" do
    distance = described_class.haversine_m(0, 0, 0, 1)

    expect(distance).to be_within(500).of(111_195)
  end
end
