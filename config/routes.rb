Rails.application.routes.draw do
  get "/health", to: "health#show"

  namespace :api do
    namespace :v1 do
      resources :tracking_sessions, only: :create do
        post :finish, on: :member
        resources :locations, only: :create do
          post :batch, on: :collection
        end
      end

      namespace :public do
        get "tracking/:public_token", to: "tracking#show"
        get "tracking/:public_token/locations", to: "tracking#locations"
      end
    end
  end
end
