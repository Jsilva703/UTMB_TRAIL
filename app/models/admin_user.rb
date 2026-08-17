class AdminUser < ApplicationRecord
  has_secure_password

  before_validation :normalize_email

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :active, inclusion: { in: [true, false] }

  def self.authenticate(email, password)
    admin_user = find_by(email: email.to_s.strip.downcase)
    return nil unless admin_user&.active?

    admin_user.authenticate(password) ? admin_user : nil
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase if email.present?
  end
end
