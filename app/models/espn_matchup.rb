class EspnMatchup < ApplicationRecord
  CONSOLATION_TIERS = %w[LOSERS_CONSOLATION_LADDER WINNERS_CONSOLATION_LADDER].freeze
  WINNERS_BRACKET = "WINNERS_BRACKET"
  REGULAR_SEASON = "NONE"
  DECIDED_WINNERS = %w[HOME AWAY TIE].freeze

  belongs_to :espn_season, inverse_of: :matchups
  belongs_to :home_espn_team_season, class_name: "EspnTeamSeason", optional: true, inverse_of: :home_matchups
  belongs_to :away_espn_team_season, class_name: "EspnTeamSeason", optional: true, inverse_of: :away_matchups

  validates :espn_matchup_id, :matchup_period, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :espn_matchup_id, uniqueness: { scope: :espn_season_id }
  validates :playoff_tier, presence: true

  scope :decided, -> { where(winner: DECIDED_WINNERS) }
  scope :regular_season, -> { where(playoff_tier: REGULAR_SEASON) }
  scope :winners_bracket, -> { where(playoff_tier: WINNERS_BRACKET) }
  scope :consolation, -> { where(playoff_tier: CONSOLATION_TIERS) }
  scope :for_franchise, ->(franchise) {
    team_seasons = franchise.team_seasons.select(:id)
    where(home_espn_team_season_id: team_seasons).or(where(away_espn_team_season_id: team_seasons))
  }
end
