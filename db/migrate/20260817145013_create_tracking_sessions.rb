class CreateTrackingSessions < ActiveRecord::Migration[6.1]
  def change
    create_table :tracking_sessions do |t|
      t.references :athlete, null: false, foreign_key: true
      t.references :race, null: false, foreign_key: true
      t.string :status, null: false, default: "active"
      t.string :public_token, null: false
      t.string :ingest_token, null: false
      t.datetime :started_at, null: false
      t.datetime :finished_at

      t.timestamps
    end

    add_index :tracking_sessions, :public_token, unique: true
    add_index :tracking_sessions, :ingest_token, unique: true
    add_index :tracking_sessions, :status
  end
end
