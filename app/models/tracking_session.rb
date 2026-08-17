class TrackingSession < ApplicationRecord
  STATUSES = %w[active finished].freeze

  belongs_to :athlete
  belongs_to :race
  has_many :location_points, dependent: :destroy

  before_validation :assign_started_at, on: :create
  before_validation :assign_tokens, on: :create

  validates :status, :public_token, :ingest_token, :started_at, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :public_token, :ingest_token, uniqueness: true
  validate :tokens_must_be_different

  scope :active, -> { where(status: "active") }

  def active?
    status == "active"
  end

  def finished?
    status == "finished"
  end

  def finish!
    return true if finished?

    update!(status: "finished", finished_at: Time.current)
  end

  def latest_location
    location_points.order(recorded_at: :desc, id: :desc).first
  end

  private

  def assign_started_at
    self.started_at ||= Time.current
  end

  def assign_tokens
    self.public_token ||= unique_token(:public_token)
    self.ingest_token ||= unique_token(:ingest_token, excluded_tokens: [public_token])
  end

  def unique_token(column, excluded_tokens: [])
    loop do
      token = SecureRandom.urlsafe_base64(32)
      break token unless excluded_tokens.include?(token) || self.class.exists?(column => token)
    end
  end

  def tokens_must_be_different
    return if public_token.blank? || ingest_token.blank? || public_token != ingest_token

    errors.add(:ingest_token, "must be different from public_token")
  end
end
