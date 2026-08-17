module Api
  module V1
    module Admin
      class RacesController < BaseController
        def index
          races = Race.includes(:race_route).order(:name, :id)
          render json: { races: races.map { |race| AdminRaceSerializer.new(race).as_json } }
        end

        def show
          race = Race.find(params[:id])
          render json: { race: AdminRaceSerializer.new(race).as_json }
        end

        def create
          race = Race.create!(race_params)
          render json: { race: AdminRaceSerializer.new(race).as_json }, status: :created
        end

        private

        def race_params
          params.permit(:name, :slug, :distance_km, :status)
        end
      end
    end
  end
end
