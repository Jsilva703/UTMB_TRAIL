require "rails_helper"

RSpec.describe "Tracking flow", type: :request do
  it "creates a session, ingests a location, estimates progress, and exposes public tracking" do
    athlete = Athlete.create!(name: "Flow Runner")
    race = Race.create!(name: "Flow Race", slug: "flow-race", distance_km: 1)
    RaceRoutes::ImportGpx.new(
      race: race,
      file_path: Rails.root.join("spec/fixtures/files/sample.gpx")
    ).call

    post "/api/v1/tracking_sessions", params: { athlete_id: athlete.id, race_id: race.id }, as: :json
    expect(response).to have_http_status(:created)

    public_token = json.fetch("public_token")
    ingest_token = json.fetch("ingest_token")
    tracking_session_id = json.fetch("id")

    post "/api/v1/tracking_sessions/#{tracking_session_id}/locations",
         params: {
           latitude: 0.001,
           longitude: 0.001,
           accuracy: 5,
           recorded_at: "2026-08-17T10:04:00-03:00",
           client_point_id: "flow-1"
         },
         headers: auth_headers(ingest_token),
         as: :json
    expect(response).to have_http_status(:created)

    get "/api/v1/public/tracking/#{public_token}"

    expect(response).to have_http_status(:ok)
    expect(json["athlete"]["name"]).to eq("Flow Runner")
    expect(json["tracking"]["last_update_at"]).to eq("2026-08-17T13:04:00Z")
    expect(json["route_progress"]["estimated_progress_percentage"]).to eq(100.0)
    expect(json["route_progress"]["distance_from_route_m"]).to be < 1
    expect(response.body).not_to include(ingest_token)
  end
end
