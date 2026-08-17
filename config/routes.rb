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
        get "tracking/:public_token/route", to: "tracking#route"
      end

      namespace :athlete, module: :athlete_portal do
        resource :session, only: :create
      end

      namespace :admin do
        resource :session, only: [:create, :destroy]
        get "dashboard", to: "dashboard#show"
        resources :athletes, only: [:index, :create, :show]
        resources :races, only: [:index, :create, :show] do
          resource :route, only: :create, controller: "race_routes"
        end
        resources :tracking_sessions, only: [:index, :create, :show]
      end
    end
  end
end
