class CreateRaceRoutes < ActiveRecord::Migration[6.1]
  def change
    create_table :race_routes do |t|
      t.references :race, null: false, foreign_key: true, index: { unique: true }
      t.string :source_filename, null: false
      t.decimal :total_distance_m, precision: 12, scale: 2, null: false, default: 0
      t.integer :points_count, null: false, default: 0

      t.timestamps
    end
  end
end
