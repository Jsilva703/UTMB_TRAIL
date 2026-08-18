require "rails_helper"

RSpec.describe "Tracking API", type: :request do
  let!(:athlete) { Athlete.create!(name: "Runner") }
  let!(:race) { Race.create!(name: "UTMB Paraty Test", slug: "utmb-paraty-test", distance_km: 55) }

  describe "POST /api/v1/tracking_sessions" do
    it "creates an active session with public and ingest tokens" do
      post "/api/v1/tracking_sessions", params: { athlete_id: athlete.id, race_id: race.id }, as: :json

      expect(response).to have_http_status(:created)
      expect(json["status"]).to eq("active")
      expect(json["public_token"]).to be_present
      expect(json["ingest_token"]).to be_present
      expect(json["athlete_access_code"]).to be_present
      expect(json["public_access_code"]).to be_present
      expect(json["public_token"]).not_to eq(json["ingest_token"])
      expect(json["public_access_code"]).not_to eq(json["athlete_access_code"])
    end
  end

  describe "POST /api/v1/athlete/session" do
    let!(:tracking_session) { TrackingSession.create!(athlete: athlete, race: race) }

    it "resolves an active athlete access code for server-side BFF use" do
      post "/api/v1/athlete/session",
           params: { code: tracking_session.athlete_access_code.downcase.insert(4, "-") },
           as: :json

      expect(response).to have_http_status(:ok)
      expect(json["athlete"]["name"]).to eq("Runner")
      expect(json["race"]["name"]).to eq("UTMB Paraty Test")
      expect(json["tracking"]["status"]).to eq("active")
      expect(json["public_access"]["code"]).to eq(tracking_session.public_access_code)
      expect(json["server_credentials"]["tracking_session_id"]).to eq(tracking_session.id)
      expect(json["server_credentials"]["ingest_token"]).to eq(tracking_session.ingest_token)
      expect(response.body).not_to include(tracking_session.public_token)
    end

    it "does not resolve the public token as an athlete access code" do
      post "/api/v1/athlete/session", params: { code: tracking_session.public_token }, as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "does not resolve finished sessions" do
      tracking_session.finish!

      post "/api/v1/athlete/session", params: { code: tracking_session.athlete_access_code }, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "location ingestion" do
    let!(:tracking_session) { TrackingSession.create!(athlete: athlete, race: race) }
    let(:payload) do
      {
        latitude: -23.123456,
        longitude: -44.123456,
        accuracy: 8.2,
        altitude: 540.0,
        recorded_at: "2026-08-17T10:30:00-03:00",
        client_point_id: "point-1"
      }
    end

    it "accepts a location with the correct ingest token" do
      post "/api/v1/tracking_sessions/#{tracking_session.id}/locations",
           params: payload,
           headers: auth_headers(tracking_session.ingest_token),
           as: :json

      expect(response).to have_http_status(:created)
      expect(json["created"]).to eq(true)
      expect(tracking_session.location_points.count).to eq(1)
    end

    it "rejects an incorrect ingest token" do
      post "/api/v1/tracking_sessions/#{tracking_session.id}/locations",
           params: payload,
           headers: auth_headers("wrong"),
           as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(tracking_session.location_points.count).to eq(0)
    end

    it "is idempotent when client_point_id is repeated" do
      2.times do
        post "/api/v1/tracking_sessions/#{tracking_session.id}/locations",
             params: payload,
             headers: auth_headers(tracking_session.ingest_token),
             as: :json
      end

      expect(response).to have_http_status(:ok)
      expect(json["created"]).to eq(false)
      expect(tracking_session.location_points.count).to eq(1)
    end

    it "does not accept locations after finish" do
      tracking_session.finish!

      post "/api/v1/tracking_sessions/#{tracking_session.id}/locations",
           params: payload,
           headers: auth_headers(tracking_session.ingest_token),
           as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it "accepts a batch and ignores duplicate client points" do
      post "/api/v1/tracking_sessions/#{tracking_session.id}/locations/batch",
           params: { locations: [payload, payload.merge(latitude: -23.2)] },
           headers: auth_headers(tracking_session.ingest_token),
           as: :json

      expect(response).to have_http_status(:created)
      expect(json["created_count"]).to eq(1)
      expect(json["duplicate_count"]).to eq(1)
      expect(tracking_session.location_points.count).to eq(1)
    end

    it "returns 422 when a required location attribute is missing" do
      post "/api/v1/tracking_sessions/#{tracking_session.id}/locations",
           params: payload.except(:latitude),
           headers: auth_headers(tracking_session.ingest_token),
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json["details"]["latitude"]).to include("can't be blank")
    end

    it "rolls back the whole batch when one item is invalid" do
      post "/api/v1/tracking_sessions/#{tracking_session.id}/locations/batch",
           params: { locations: [payload.merge(client_point_id: "valid"), payload.merge(latitude: 91, client_point_id: "invalid")] },
           headers: auth_headers(tracking_session.ingest_token),
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(tracking_session.location_points.count).to eq(0)
    end

    it "does not duplicate a retried batch when client_point_id is present" do
      params = { locations: [payload.merge(client_point_id: "retry-1"), payload.merge(client_point_id: "retry-2", recorded_at: "2026-08-17T10:31:00-03:00")] }

      2.times do
        post "/api/v1/tracking_sessions/#{tracking_session.id}/locations/batch",
             params: params,
             headers: auth_headers(tracking_session.ingest_token),
             as: :json
      end

      expect(response).to have_http_status(:created)
      expect(json["created_count"]).to eq(0)
      expect(json["duplicate_count"]).to eq(2)
      expect(tracking_session.location_points.count).to eq(2)
    end
  end

  describe "public tracking" do
    let!(:tracking_session) { TrackingSession.create!(athlete: athlete, race: race) }

    before do
      route = RaceRoute.create!(race: race, source_filename: "sample.gpx", total_distance_m: 1000, points_count: 2)
      RoutePoint.create!(race_route: route, sequence: 0, latitude: -23.12, longitude: -44.12, cumulative_distance_m: 0)
      RoutePoint.create!(race_route: route, sequence: 1, latitude: -23.13, longitude: -44.13, cumulative_distance_m: 1000)
      tracking_session.location_points.create!(
        latitude: -23.13,
        longitude: -44.13,
        accuracy: 10,
        recorded_at: "2026-08-17T10:30:00-03:00"
      )
      tracking_session.location_points.create!(
        latitude: -23.12,
        longitude: -44.12,
        accuracy: 10,
        recorded_at: "2026-08-17T10:00:00-03:00"
      )
    end

    it "returns the public tracking payload without ingest_token" do
      get "/api/v1/public/tracking/#{tracking_session.public_token}"

      expect(response).to have_http_status(:ok)
      expect(json["athlete"]["name"]).to eq("Runner")
      expect(json["tracking"]["last_update_at"]).to be_present
      expect(json["distance_traveled"]).to include(
        "estimated_distance_m",
        "estimated_distance_km",
        "accepted_points_count",
        "rejected_points_count"
      )
      expect(json["route_progress"]["estimated_progress_percentage"]).to eq(100.0)
      expect(json["route_progress"]["route_progress_m"]).to eq(1000.0)
      expect(json["route_progress"]["distance_from_route_m"]).to be_present
      expect(json["location"]["latitude"]).to eq(-23.13)
      expect(response.body).not_to include(tracking_session.ingest_token)
    end

    it "uses the latest valid filtered location in the public payload" do
      tracking_session.location_points.create!(
        latitude: -22.0,
        longitude: -44.0,
        accuracy: 360,
        recorded_at: "2026-08-17T10:45:00-03:00"
      )

      get "/api/v1/public/tracking/#{tracking_session.public_token}"

      expect(response).to have_http_status(:ok)
      expect(json["location"]["latitude"]).to eq(-23.13)
      expect(json["distance_traveled"]["rejected_points_count"]).to be >= 1
    end

    it "resolves public tracking by public access code" do
      get "/api/v1/public/tracking/code/#{tracking_session.public_access_code}"

      expect(response).to have_http_status(:ok)
      expect(json["athlete"]["name"]).to eq("Runner")
      expect(response.body).not_to include(tracking_session.ingest_token)
      expect(response.body).not_to include(tracking_session.athlete_access_code)
      expect(response.body).not_to include(tracking_session.public_token)
    end

    it "returns paginated public locations in ascending order" do
      get "/api/v1/public/tracking/#{tracking_session.public_token}/locations", params: { per_page: 1 }

      expect(response).to have_http_status(:ok)
      expect(json["locations"].size).to eq(1)
      expect(json["pagination"]["per_page"]).to eq(1)
      expect(response.body).not_to include("tracking_session_id")
    end

    it "returns paginated public locations by public access code" do
      get "/api/v1/public/tracking/code/#{tracking_session.public_access_code}/locations", params: { per_page: 1 }

      expect(response).to have_http_status(:ok)
      expect(json["locations"].size).to eq(1)
      expect(response.body).not_to include("tracking_session_id")
    end

    it "returns the public race route without internal ids or tokens" do
      get "/api/v1/public/tracking/#{tracking_session.public_token}/route"

      expect(response).to have_http_status(:ok)
      expect(json["route"]).to include(
        "source_filename" => "sample.gpx",
        "total_distance_m" => 1000.0,
        "points_count" => 2
      )
      expect(json["route"].keys).to contain_exactly(
        "source_filename",
        "total_distance_m",
        "points_count",
        "points"
      )
      expect(response.body).not_to include("id")
      expect(response.body).not_to include("race_id")
      expect(response.body).not_to include("race_route_id")
      expect(response.body).not_to include("public_token")
      expect(response.body).not_to include("ingest_token")
      expect(response.body).not_to include("athlete_access_code")
      expect(response.body).not_to include(tracking_session.ingest_token)
    end

    it "returns the public race route by public access code" do
      get "/api/v1/public/tracking/code/#{tracking_session.public_access_code}/route"

      expect(response).to have_http_status(:ok)
      expect(json["route"]["points"].map { |point| point["sequence"] }).to eq([0, 1])
      expect(response.body).not_to include("public_token")
      expect(response.body).not_to include("ingest_token")
      expect(response.body).not_to include("athlete_access_code")
    end

    it "returns route points ordered by sequence with the expected fields" do
      route = race.race_route
      RoutePoint.create!(
        race_route: route,
        sequence: 2,
        latitude: -23.14,
        longitude: -44.14,
        altitude: 710.5,
        cumulative_distance_m: 1200
      )

      get "/api/v1/public/tracking/#{tracking_session.public_token}/route"

      expect(response).to have_http_status(:ok)
      expect(json["route"]["points"].map { |point| point["sequence"] }).to eq([0, 1, 2])
      expect(json["route"]["points"].first).to eq(
        "sequence" => 0,
        "latitude" => -23.12,
        "longitude" => -44.12,
        "altitude" => nil,
        "cumulative_distance_m" => 0.0
      )
      expect(json["route"]["points"].last).to eq(
        "sequence" => 2,
        "latitude" => -23.14,
        "longitude" => -44.14,
        "altitude" => 710.5,
        "cumulative_distance_m" => 1200.0
      )
    end

    it "returns null route when the tracking session race has no route" do
      race.race_route.destroy!

      get "/api/v1/public/tracking/#{tracking_session.public_token}/route"

      expect(response).to have_http_status(:ok)
      expect(json).to eq("route" => nil)
    end

    it "returns not found for an unknown public token" do
      get "/api/v1/public/tracking/missing"

      expect(response).to have_http_status(:not_found)
    end

    it "returns not found for an unknown public access code" do
      get "/api/v1/public/tracking/code/000000"

      expect(response).to have_http_status(:not_found)
    end

    it "returns not found for route with an unknown public token" do
      get "/api/v1/public/tracking/missing/route"

      expect(response).to have_http_status(:not_found)
    end

    it "does not allow public access code to write locations" do
      post "/api/v1/tracking_sessions/#{tracking_session.id}/locations",
           params: {
             latitude: -23.13,
             longitude: -44.13,
             recorded_at: "2026-08-17T10:45:00-03:00"
           },
           headers: auth_headers(tracking_session.public_access_code),
           as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/tracking_sessions/:id/finish" do
    let!(:tracking_session) { TrackingSession.create!(athlete: athlete, race: race) }

    it "finishes a tracking session with the ingest token" do
      post "/api/v1/tracking_sessions/#{tracking_session.id}/finish",
           headers: auth_headers(tracking_session.ingest_token),
           as: :json

      expect(response).to have_http_status(:ok)
      expect(json["tracking"]["status"]).to eq("finished")
      expect(tracking_session.reload.finished_at).to be_present
    end
  end
end
