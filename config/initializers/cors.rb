# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

admin_frontend_origins = ENV.fetch(
  "ADMIN_FRONTEND_ORIGIN",
  "http://localhost:3001,http://localhost:3000"
).split(",").map(&:strip).reject(&:blank?)

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*admin_frontend_origins)

    resource "/api/v1/admin/*",
             headers: :any,
             methods: [:get, :post, :delete, :options, :head],
             credentials: true
  end
end
