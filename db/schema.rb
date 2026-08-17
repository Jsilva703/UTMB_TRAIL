# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2026_08_17_190000) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admin_users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["active"], name: "index_admin_users_on_active"
    t.index ["email"], name: "index_admin_users_on_email", unique: true
  end

  create_table "athletes", force: :cascade do |t|
    t.string "name", null: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["status"], name: "index_athletes_on_status"
  end

  create_table "location_points", force: :cascade do |t|
    t.bigint "tracking_session_id", null: false
    t.decimal "latitude", precision: 10, scale: 6, null: false
    t.decimal "longitude", precision: 10, scale: 6, null: false
    t.decimal "accuracy", precision: 10, scale: 2
    t.decimal "altitude", precision: 10, scale: 2
    t.datetime "recorded_at", null: false
    t.string "client_point_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["tracking_session_id", "client_point_id"], name: "idx_location_points_session_client_point", unique: true, where: "(client_point_id IS NOT NULL)"
    t.index ["tracking_session_id", "recorded_at"], name: "index_location_points_on_tracking_session_id_and_recorded_at"
    t.index ["tracking_session_id"], name: "index_location_points_on_tracking_session_id"
  end

  create_table "race_routes", force: :cascade do |t|
    t.bigint "race_id", null: false
    t.string "source_filename", null: false
    t.decimal "total_distance_m", precision: 12, scale: 2, default: "0.0", null: false
    t.integer "points_count", default: 0, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["race_id"], name: "index_race_routes_on_race_id", unique: true
  end

  create_table "races", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.decimal "distance_km", precision: 10, scale: 3, null: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["slug"], name: "index_races_on_slug", unique: true
    t.index ["status"], name: "index_races_on_status"
  end

  create_table "route_points", force: :cascade do |t|
    t.bigint "race_route_id", null: false
    t.integer "sequence", null: false
    t.decimal "latitude", precision: 10, scale: 6, null: false
    t.decimal "longitude", precision: 10, scale: 6, null: false
    t.decimal "altitude", precision: 10, scale: 2
    t.decimal "cumulative_distance_m", precision: 12, scale: 2, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["race_route_id", "sequence"], name: "index_route_points_on_race_route_id_and_sequence", unique: true
    t.index ["race_route_id"], name: "index_route_points_on_race_route_id"
  end

  create_table "tracking_sessions", force: :cascade do |t|
    t.bigint "athlete_id", null: false
    t.bigint "race_id", null: false
    t.string "status", default: "active", null: false
    t.string "public_token", null: false
    t.string "ingest_token", null: false
    t.datetime "started_at", null: false
    t.datetime "finished_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["athlete_id"], name: "index_tracking_sessions_on_athlete_id"
    t.index ["ingest_token"], name: "index_tracking_sessions_on_ingest_token", unique: true
    t.index ["public_token"], name: "index_tracking_sessions_on_public_token", unique: true
    t.index ["race_id"], name: "index_tracking_sessions_on_race_id"
    t.index ["status"], name: "index_tracking_sessions_on_status"
  end

  add_foreign_key "location_points", "tracking_sessions"
  add_foreign_key "race_routes", "races"
  add_foreign_key "route_points", "race_routes"
  add_foreign_key "tracking_sessions", "athletes"
  add_foreign_key "tracking_sessions", "races"
end
