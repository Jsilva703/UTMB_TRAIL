require 'rails_helper'

RSpec.describe TrackingSession, type: :model do
  let(:athlete) { Athlete.create!(name: "Runner") }
  let(:race) { Race.create!(name: "Race", slug: "race", distance_km: 10) }

  it "generates distinct secure tokens and started_at on create" do
    session = described_class.create!(athlete: athlete, race: race)

    expect(session.status).to eq("active")
    expect(session.started_at).to be_present
    expect(session.public_token).to be_present
    expect(session.ingest_token).to be_present
    expect(session.athlete_access_code).to match(/\A[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{8}\z/)
    expect(session.public_token).not_to eq(session.ingest_token)
  end

  it "normalizes athlete access codes typed with separators or lowercase" do
    expect(described_class.normalize_athlete_access_code("ab23-cd45")).to eq("AB23CD45")
  end

  it "does not allow public_token and ingest_token to be equal" do
    session = described_class.new(
      athlete: athlete,
      race: race,
      public_token: "same-token",
      ingest_token: "same-token"
    )

    expect(session).not_to be_valid
    expect(session.errors[:ingest_token]).to include("must be different from public_token")
  end

  it "finishes once without changing finished_at on repeated calls" do
    session = described_class.create!(athlete: athlete, race: race)

    session.finish!
    finished_at = session.finished_at
    session.finish!

    expect(session.reload).to be_finished
    expect(session.finished_at.to_i).to eq(finished_at.to_i)
  end
end
