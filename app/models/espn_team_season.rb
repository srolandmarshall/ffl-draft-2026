class EspnTeamSeason < ApplicationRecord
  belongs_to :espn_season, inverse_of: :team_seasons
  belongs_to :espn_franchise, optional: true, inverse_of: :team_seasons
  has_many :home_matchups, class_name: "EspnMatchup", foreign_key: :home_espn_team_season_id, dependent: :restrict_with_exception, inverse_of: :home_espn_team_season
  has_many :away_matchups, class_name: "EspnMatchup", foreign_key: :away_espn_team_season_id, dependent: :restrict_with_exception, inverse_of: :away_espn_team_season

  validates :espn_team_id, numericality: { only_integer: true, greater_than: 0 }, uniqueness: { scope: :espn_season_id }
  validates :espn_franchise_id, uniqueness: { scope: :espn_season_id }, allow_nil: true
  validates :team_name, :team_abbreviation, presence: true
  validates :wins, :losses, :ties, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :regular_season_rank, :playoff_seed, :playoff_finish,
    numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  def record
    [ wins, losses, ties ].join("-")
  end

  def win_pct
    games = wins + losses + ties
    return 0.0 if games.zero?

    ((wins + ties.fdiv(2)) / games).round(3)
  end

  def made_playoffs? = playoff_seed.present?
  def champion? = playoff_finish == 1

  def playoff_result_label
    case playoff_finish
    when 1 then "Champion"
    when 2 then "Runner-up"
    when 3 then "Lost in semifinals"
    when 5 then "Lost in the first round"
    else made_playoffs? ? "Playoff result pending" : "Missed the playoffs"
    end
  end
end
