require 'rails_helper'

RSpec.describe Athlete, type: :model do
  it "validates name and status" do
    athlete = described_class.new(name: "Test Athlete", status: "active")

    expect(athlete).to be_valid

    athlete.status = "unknown"
    expect(athlete).not_to be_valid
  end
end
