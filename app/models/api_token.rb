class ApiToken < ApplicationRecord
  TOKEN_PREFIX = "ffld_"
  DEFAULT_LIFETIME = 2.hours

  belongs_to :user

  validates :token_digest, :expires_at, presence: true
  validates :token_digest, uniqueness: true

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  def self.issue!(user:, label: nil, expires_in: DEFAULT_LIFETIME)
    raw_token = "#{TOKEN_PREFIX}#{SecureRandom.urlsafe_base64(32)}"
    create!(
      user:,
      token_digest: digest(raw_token),
      expires_at: expires_in.from_now,
      label:
    )
    raw_token
  end

  def self.find_by_raw_token(raw_token)
    return if raw_token.blank?

    active.find_by(token_digest: digest(raw_token))
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def active?
    revoked_at.blank? && expires_at&.future?
  end

  def self.digest(raw_token)
    OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, raw_token.to_s)
  end

  private_class_method :digest
end
