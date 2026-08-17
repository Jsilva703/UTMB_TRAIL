class CreateRoutePoints < ActiveRecord::Migration[6.1]
  def change
    create_table :route_points do |t|
      t.references :race_route, null: false, foreign_key: true
      t.integer :sequence, null: false
      t.decimal :latitude, precision: 10, scale: 6, null: false
      t.decimal :longitude, precision: 10, scale: 6, null: false
      t.decimal :altitude, precision: 10, scale: 2
      t.decimal :cumulative_distance_m, precision: 12, scale: 2, null: false

      t.timestamps
    end

    add_index :route_points, [:race_route_id, :sequence], unique: true
  end
end
