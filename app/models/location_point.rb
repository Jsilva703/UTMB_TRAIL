class LocationPoint < ApplicationRecord
  belongs_to :tracking_session

  validates :latitude, :longitude, :recorded_at, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
  validates :client_point_id, uniqueness: { scope: :tracking_session_id, allow_blank: true }
  validate :tracking_session_must_be_active, on: :create

  private

  def tracking_session_must_be_active
    return if tracking_session.blank? || tracking_session.active?

    errors.add(:tracking_session, "must be active")
  end
end
