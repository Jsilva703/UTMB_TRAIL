require "rails_helper"

RSpec.describe "Admin API", type: :request do
  let!(:admin_user) { AdminUser.create!(email: "admin@example.com", password: "password123") }
  let!(:athlete) { Athlete.create!(name: "Runner") }
  let!(:race) { Race.create!(name: "UTMB Paraty 58K", slug: "utmb-paraty-58k", distance_km: 58) }

  describe "authentication" do
    it "logs in with valid credentials" do
      post "/api/v1/admin/session", params: { email: "ADMIN@example.com", password: "password123" }, as: :json

      expect(response).to have_http_status(:created)
      expect(json["admin_user"]["email"]).to eq("admin@example.com")
      expect(response.body).not_to include("password")
    end

    it "rejects invalid credentials" do
      post "/api/v1/admin/session", params: { email: admin_user.email, password: "wrong" }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects inactive admins" do
      admin_user.update!(active: false)

      post "/api/v1/admin/session", params: { email: admin_user.email, password: "password123" }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects admin endpoints without authentication" do
      get "/api/v1/admin/athletes"

      expect(response).to have_http_status(:unauthorized)
    end

    it "allows admin endpoints after authentication" do
      login_admin(admin_user)

      get "/api/v1/admin/athletes"

      expect(response).to have_http_status(:ok)
    end
  end

  describe "admin athletes" do
    before { login_admin(admin_user) }

    it "creates athletes" do
      post "/api/v1/admin/athletes", params: { name: "João Teste" }, as: :json

      expect(response).to have_http_status(:created)
      expect(json["athlete"]["name"]).to eq("João Teste")
      expect(json["athlete"]["status"]).to eq("active")
    end

    it "lists athletes with active tracking status" do
      TrackingSession.create!(athlete: athlete, race: race)

      get "/api/v1/admin/athletes"

      expect(response).to have_http_status(:ok)
      expect(json["athletes"].first["has_active_tracking"]).to eq(true)
      expect(json["athletes"].first["active_tracking_session"]["public_token"]).to be_present
    end

    it "shows an athlete" do
      get "/api/v1/admin/athletes/#{athlete.id}"

      expect(response).to have_http_status(:ok)
      expect(json["athlete"]["id"]).to eq(athlete.id)
    end
  end

  describe "admin races" do
    before { login_admin(admin_user) }

    it "creates races" do
      post "/api/v1/admin/races",
           params: { name: "UTMB Paraty 108K", slug: "utmb-paraty-108k", distance_km: 108, status: "active" },
           as: :json

      expect(response).to have_http_status(:created)
      expect(json["race"]["name"]).to eq("UTMB Paraty 108K")
      expect(json["race"]["published"]).to eq(true)
    end

    it "lists races with route and tracking metrics" do
      RaceRoute.create!(race_id: race.id, source_filename: "route.gpx", total_distance_m: 1000, points_count: 2)
      TrackingSession.create!(athlete: athlete, race: race)

      get "/api/v1/admin/races"

      expect(response).to have_http_status(:ok)
      expect(json["races"].first["has_route"]).to eq(true)
      expect(json["races"].first["route_points_count"]).to eq(2)
      expect(json["races"].first["tracking_sessions_count"]).to eq(1)
      expect(json["races"].first["active_tracking_sessions_count"]).to eq(1)
    end

    it "shows a race" do
      get "/api/v1/admin/races/#{race.id}"

      expect(response).to have_http_status(:ok)
      expect(json["race"]["id"]).to eq(race.id)
    end
  end

  describe "admin GPX import" do
    before { login_admin(admin_user) }

    it "imports a valid GPX into a race route" do
      file = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/sample.gpx"), "application/gpx+xml")

      post "/api/v1/admin/races/#{race.id}/route", params: { file: file }

      expect(response).to have_http_status(:created)
      expect(json["route"]["points_count"]).to eq(3)
      expect(race.reload.race_route.route_points.count).to eq(3)
    end

    it "rejects invalid GPX files" do
      file = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/invalid.gpx"), "application/gpx+xml")

      post "/api/v1/admin/races/#{race.id}/route", params: { file: file }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns not found for missing races" do
      file = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/sample.gpx"), "application/gpx+xml")

      post "/api/v1/admin/races/999/route", params: { file: file }

      expect(response).to have_http_status(:not_found)
    end

    it "protects import by authentication" do
      delete "/api/v1/admin/session"
      file = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/sample.gpx"), "application/gpx+xml")

      post "/api/v1/admin/races/#{race.id}/route", params: { file: file }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "admin tracking sessions" do
    before { login_admin(admin_user) }

    it "creates tracking sessions" do
      post "/api/v1/admin/tracking_sessions", params: { athlete_id: athlete.id, race_id: race.id }, as: :json

      expect(response).to have_http_status(:created)
      expect(json["tracking_session"]["public_token"]).to be_present
      expect(json["tracking_session"]["ingest_token"]).to be_present
      expect(json["tracking_session"]["athlete"]["id"]).to eq(athlete.id)
    end

    it "lists and filters tracking sessions" do
      active_session = TrackingSession.create!(athlete: athlete, race: race)
      finished_session = TrackingSession.create!(athlete: athlete, race: race)
      finished_session.finish!

      get "/api/v1/admin/tracking_sessions", params: { active: true }

      expect(response).to have_http_status(:ok)
      expect(json["tracking_sessions"].map { |session| session["id"] }).to eq([active_session.id])

      get "/api/v1/admin/tracking_sessions", params: { finished: true, race_id: race.id, athlete_id: athlete.id }

      expect(response).to have_http_status(:ok)
      expect(json["tracking_sessions"].map { |session| session["id"] }).to eq([finished_session.id])
    end

    it "shows tracking session details with latest location" do
      tracking_session = TrackingSession.create!(athlete: athlete, race: race)
      tracking_session.location_points.create!(
        latitude: -23.12,
        longitude: -44.12,
        accuracy: 10,
        recorded_at: "2026-08-17T10:00:00Z"
      )

      get "/api/v1/admin/tracking_sessions/#{tracking_session.id}"

      expect(response).to have_http_status(:ok)
      expect(json["tracking_session"]["latest_location"]["latitude"]).to eq(-23.12)
    end
  end

  describe "admin dashboard" do
    before { login_admin(admin_user) }

    it "returns dashboard metrics" do
      TrackingSession.create!(athlete: athlete, race: race)
      finished_session = TrackingSession.create!(athlete: athlete, race: race)
      finished_session.finish!
      RaceRoute.create!(race_id: race.id, source_filename: "route.gpx", total_distance_m: 1000, points_count: 2)

      get "/api/v1/admin/dashboard"

      expect(response).to have_http_status(:ok)
      expect(json["total_athletes"]).to eq(1)
      expect(json["athletes_tracking_now"]).to eq(1)
      expect(json["total_races"]).to eq(1)
      expect(json["races_with_route"]).to eq(1)
      expect(json["active_tracking_sessions"]).to eq(1)
      expect(json["finished_tracking_sessions"]).to eq(1)
      expect(json["races"].first["active_tracking_sessions_count"]).to eq(1)
    end
  end
end
