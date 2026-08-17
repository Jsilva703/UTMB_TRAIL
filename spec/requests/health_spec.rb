require "rails_helper"

RSpec.describe "Health", type: :request do
  it "returns ok" do
    get "/health"

    expect(response).to have_http_status(:ok)
    expect(json).to eq("status" => "ok")
  end
end
