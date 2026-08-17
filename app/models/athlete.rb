class Athlete < ApplicationRecord
  STATUSES = %w[active inactive].freeze

  has_many :tracking_sessions, dependent: :restrict_with_error

  validates :name, :status, presence: true
  validates :status, inclusion: { in: STATUSES }
end
