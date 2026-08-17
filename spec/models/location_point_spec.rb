require 'rails_helper'

RSpec.describe LocationPoint, type: :model do
  let(:athlete) { Athlete.create!(name: "Runner") }
  let(:race) { Race.create!(name: "Race", slug: "race", distance_km: 10) }
  let(:tracking_session) { TrackingSession.create!(athlete: athlete, race: race) }

  it "validates coordinates and recorded_at" do
    point = described_class.new(
      tracking_session: tracking_session,
      latitude: 10,
      longitude: 20,
      recorded_at: Time.current
    )

    expect(point).to be_valid

    point.latitude = 91
    point.longitude = -181
    expect(point).not_to be_valid
  end

  it "enforces idempotency by client_point_id within a tracking session" do
    described_class.create!(
      tracking_session: tracking_session,
      latitude: 10,
      longitude: 20,
      recorded_at: Time.current,
      client_point_id: "point-1"
    )

    duplicate = described_class.new(
      tracking_session: tracking_session,
      latitude: 11,
      longitude: 21,
      recorded_at: Time.current,
      client_point_id: "point-1"
    )

    expect(duplicate).not_to be_valid
  end

  it "does not allow locations after tracking is finished" do
    tracking_session.finish!

    point = described_class.new(
      tracking_session: tracking_session,
      latitude: 10,
      longitude: 20,
      recorded_at: Time.current
    )

    expect(point).not_to be_valid
  end
end
