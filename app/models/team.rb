class Team < ApplicationRecord
  belongs_to :league

  has_many :draft_entries, dependent: :restrict_with_error
  has_one :espn_franchise, dependent: :nullify
  has_many :picks, dependent: :restrict_with_error
  has_many :team_memberships, dependent: :destroy
  has_many :users, through: :team_memberships

  normalizes :abbreviation, with: ->(value) { value.strip.upcase }

  before_validation :assign_draft_order, on: :create

  validates :name, :owner_name, :abbreviation, presence: true
  validates :name, uniqueness: { scope: :league_id }
  validates :abbreviation, length: { in: 2..5 }, uniqueness: { scope: :league_id }
  validates :draft_order, numericality: { only_integer: true, greater_than: 0 }
  validates :espn_team_id, uniqueness: { scope: :league_id }, allow_nil: true

  scope :in_draft_order, -> { order(:draft_order, :id) }

  def emails
    users.includes(:user_emails).flat_map(&:emails).uniq.sort
  end

  private

  def assign_draft_order
    return if draft_order.to_i.positive? || league.nil?

    self.draft_order = league.teams.maximum(:draft_order).to_i + 1
  end
end
