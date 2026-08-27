class User < ApplicationRecord
  LOGIN_CODE_LIFETIME = 10.minutes
  LOGIN_CODE_RESEND_DELAY = 1.minute
  LOGIN_CODE_MAX_ATTEMPTS = 5

  has_many :team_memberships, dependent: :destroy
  has_many :teams, through: :team_memberships
  has_many :user_emails, dependent: :destroy

  enum :role, { member: 0, commissioner: 1 }

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :email, presence: true, uniqueness: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }

  after_create :add_primary_email

  def self.find_by_any_email(email)
    normalized_email = email.to_s.strip.downcase
    joins(:user_emails).find_by(user_emails: { email: normalized_email }) || find_by(email: normalized_email)
  end

  def self.find_or_create_by_any_email!(email)
    normalized_email = email.to_s.strip.downcase
    find_by_any_email(normalized_email) || create!(email: normalized_email)
  end

  def emails
    ([ email ] + user_emails.pluck(:email)).compact.uniq.sort
  end

  def allowed_to_sign_in?
    commissioner? || team_memberships.exists?
  end

  def login_code_request_allowed?
    login_code_sent_at.blank? || login_code_sent_at <= LOGIN_CODE_RESEND_DELAY.ago
  end

  def issue_login_code!(code: SecureRandom.random_number(1_000_000).to_s.rjust(6, "0"))
    update!(
      login_code_digest: digest_login_code(code),
      login_code_expires_at: LOGIN_CODE_LIFETIME.from_now,
      login_code_sent_at: Time.current,
      login_code_attempts: 0
    )

    code
  end

  def verify_login_code!(code)
    return false unless login_code_digest.present? && login_code_expires_at&.future?
    return false if login_code_attempts >= LOGIN_CODE_MAX_ATTEMPTS

    if ActiveSupport::SecurityUtils.secure_compare(login_code_digest, digest_login_code(code))
      update!(login_code_digest: nil, login_code_expires_at: nil, login_code_attempts: 0)
      true
    else
      increment!(:login_code_attempts)
      false
    end
  end

  private

  def add_primary_email
    user_emails.find_or_create_by!(email:)
  end

  def digest_login_code(code)
    Digest::SHA256.hexdigest("#{Rails.application.secret_key_base}:#{code}")
  end
end
