class EspnTeamSeason < ApplicationRecord
  belongs_to :espn_season, inverse_of: :team_seasons
  belongs_to :espn_franchise, optional: true, inverse_of: :team_seasons

  validates :espn_team_id, numericality: { only_integer: true, greater_than: 0 }, uniqueness: { scope: :espn_season_id }
  validates :espn_franchise_id, uniqueness: { scope: :espn_season_id }, allow_nil: true
  validates :team_name, :team_abbreviation, presence: true
  validates :wins, :losses, :ties, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :regular_season_rank, :playoff_seed, :playoff_finish,
    numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
end
