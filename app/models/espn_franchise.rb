class EspnFranchise < ApplicationRecord
  belongs_to :league
  belongs_to :team, optional: true
  has_many :draft_picks, class_name: "EspnDraftPick", dependent: :nullify, inverse_of: :espn_franchise
  has_many :team_seasons, class_name: "EspnTeamSeason", dependent: :nullify, inverse_of: :espn_franchise

  validates :key, :name, presence: true
  validates :key, uniqueness: { scope: :league_id }
  validate :team_belongs_to_league

  def matches_alias?(abbreviation)
    aliases.any? { |value| value.casecmp?(abbreviation.to_s) }
  end

  def matches_owner_ids?(ids)
    (owner_ids & Array(ids)).any?
  end

  private

  def team_belongs_to_league
    errors.add(:team, "must belong to the same league") if team && team.league_id != league_id
  end
end
