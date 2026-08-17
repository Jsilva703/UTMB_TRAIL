require 'rails_helper'

RSpec.describe Race, type: :model do
  it "validates required fields and status" do
    race = described_class.new(name: "UTMB Paraty 55K", slug: "utmb-paraty-55k", distance_km: 55, status: "active")

    expect(race).to be_valid

    race.status = "draft"
    expect(race).not_to be_valid
  end

  it "requires a unique slug" do
    described_class.create!(name: "Race", slug: "race", distance_km: 10, status: "active")
    duplicate = described_class.new(name: "Race 2", slug: "race", distance_km: 20, status: "active")

    expect(duplicate).not_to be_valid
  end
end
