class EspnDraftPick < ApplicationRecord
  belongs_to :espn_season, inverse_of: :draft_picks
  belongs_to :espn_franchise, optional: true, inverse_of: :draft_picks

  validates :overall_number, :round, :round_pick, :espn_team_id,
    numericality: { only_integer: true, greater_than: 0 }
  validates :espn_player_id, numericality: { only_integer: true, other_than: 0 }
  validates :espn_player_id, exclusion: { in: [ -1 ], message: "is an undrafted ESPN placeholder" }
  validates :overall_number, uniqueness: { scope: :espn_season_id }
  validates :team_name, :team_abbreviation, :player_name, presence: true
end
