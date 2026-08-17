class AddAthleteAccessCodeToTrackingSessions < ActiveRecord::Migration[6.1]
  CODE_ALPHABET = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ".freeze

  class MigrationTrackingSession < ActiveRecord::Base
    self.table_name = "tracking_sessions"
  end

  def up
    add_column :tracking_sessions, :athlete_access_code, :string

    MigrationTrackingSession.reset_column_information
    MigrationTrackingSession.find_each do |tracking_session|
      tracking_session.update_columns(athlete_access_code: unique_code)
    end

    change_column_null :tracking_sessions, :athlete_access_code, false
    add_index :tracking_sessions, :athlete_access_code, unique: true
  end

  def down
    remove_index :tracking_sessions, :athlete_access_code
    remove_column :tracking_sessions, :athlete_access_code
  end

  private

  def unique_code
    loop do
      code = 8.times.map { CODE_ALPHABET[SecureRandom.random_number(CODE_ALPHABET.length)] }.join
      break code unless MigrationTrackingSession.exists?(athlete_access_code: code)
    end
  end
end
