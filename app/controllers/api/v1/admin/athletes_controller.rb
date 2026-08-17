module Api
  module V1
    module Admin
      class AthletesController < BaseController
        def index
          athletes = Athlete.order(:name, :id)
          render json: { athletes: athletes.map { |athlete| AdminAthleteSerializer.new(athlete).as_json } }
        end

        def show
          athlete = Athlete.find(params[:id])
          render json: { athlete: AdminAthleteSerializer.new(athlete).as_json }
        end

        def create
          athlete = Athlete.create!(athlete_params)
          render json: { athlete: AdminAthleteSerializer.new(athlete).as_json }, status: :created
        end

        private

        def athlete_params
          params.permit(:name, :status)
        end
      end
    end
  end
end
