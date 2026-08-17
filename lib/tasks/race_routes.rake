namespace :race_routes do
  desc "Import a GPX file into a race route. Usage: RACE_ID=1 FILE=data/routes/utmb_paraty_55k.gpx"
  task import: :environment do
    race_id = ENV.fetch("RACE_ID")
    file = ENV.fetch("FILE")

    race = Race.find(race_id)
    result = RaceRoutes::ImportGpx.new(
      race: race,
      file_path: Rails.root.join(file)
    ).call

    puts "Imported route #{result.race_route.id} for race #{race.id}: #{result.race_route.points_count} points, #{result.race_route.total_distance_m.to_f.round(2)}m"
  end
end
