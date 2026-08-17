Athlete.find_or_create_by!(name: "Test Athlete") do |athlete|
  athlete.status = "active"
end

Race.find_or_create_by!(slug: "utmb-paraty-test") do |race|
  race.name = "UTMB Paraty Test"
  race.distance_km = 55
  race.status = "active"
end
