class User < ApplicationRecord
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

  private

  def add_primary_email
    user_emails.find_or_create_by!(email:)
  end
end
