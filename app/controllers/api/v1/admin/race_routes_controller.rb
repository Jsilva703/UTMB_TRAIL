require "tempfile"

module Api
  module V1
    module Admin
      class RaceRoutesController < BaseController
        def create
          race = Race.find(params[:race_id])
          uploaded_file = params[:file]
          return render json: { error: "file is required" }, status: :unprocessable_entity unless uploaded_file.respond_to?(:original_filename)

          original_filename = File.basename(uploaded_file.original_filename.to_s)
          return render json: { error: "file must be a .gpx" }, status: :unprocessable_entity unless original_filename.downcase.end_with?(".gpx")

          import_uploaded_file(race, uploaded_file, original_filename)
        end

        private

        def import_uploaded_file(race, uploaded_file, original_filename)
          Dir.mktmpdir("race-route-import") do |dir|
            file_path = Rails.root.join(dir, original_filename)
            File.binwrite(file_path, uploaded_file.read)
            result = RaceRoutes::ImportGpx.new(race: race, file_path: file_path).call

            render json: PublicRaceRouteSerializer.new(result.race_route).as_json, status: :created
          end
        rescue ArgumentError, Nokogiri::XML::SyntaxError => e
          render json: { error: e.message }, status: :unprocessable_entity
        end
      end
    end
  end
end
