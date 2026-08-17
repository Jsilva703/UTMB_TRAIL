class AddPublicAccessCodeToTrackingSessions < ActiveRecord::Migration[6.1]
  class MigrationTrackingSession < ActiveRecord::Base
    self.table_name = "tracking_sessions"
  end

  def up
    add_column :tracking_sessions, :public_access_code, :string

    MigrationTrackingSession.reset_column_information
    MigrationTrackingSession.find_each do |tracking_session|
      tracking_session.update_columns(public_access_code: unique_code)
    end

    change_column_null :tracking_sessions, :public_access_code, false
    add_index :tracking_sessions, :public_access_code, unique: true
  end

  def down
    remove_index :tracking_sessions, :public_access_code
    remove_column :tracking_sessions, :public_access_code
  end

  private

  def unique_code
    loop do
      code = SecureRandom.random_number(1_000_000).to_s.rjust(6, "0")
      break code unless MigrationTrackingSession.exists?(public_access_code: code)
    end
  end
end
