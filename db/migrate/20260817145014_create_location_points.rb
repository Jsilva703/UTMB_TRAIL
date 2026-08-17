class CreateLocationPoints < ActiveRecord::Migration[6.1]
  def change
    create_table :location_points do |t|
      t.references :tracking_session, null: false, foreign_key: true
      t.decimal :latitude, precision: 10, scale: 6, null: false
      t.decimal :longitude, precision: 10, scale: 6, null: false
      t.decimal :accuracy, precision: 10, scale: 2
      t.decimal :altitude, precision: 10, scale: 2
      t.datetime :recorded_at, null: false
      t.string :client_point_id

      t.timestamps
    end

    add_index :location_points, [:tracking_session_id, :recorded_at]
    add_index :location_points,
              [:tracking_session_id, :client_point_id],
              unique: true,
              name: "idx_location_points_session_client_point",
              where: "client_point_id IS NOT NULL"
  end
end
