class Race < ApplicationRecord
  STATUSES = %w[active inactive].freeze

  has_one :race_route, dependent: :destroy
  has_many :tracking_sessions, dependent: :restrict_with_error

  validates :name, :slug, :distance_km, :status, presence: true
  validates :slug, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :distance_km, numericality: { greater_than: 0 }
end
