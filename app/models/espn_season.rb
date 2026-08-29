class EspnSeason < ApplicationRecord
  belongs_to :league
  has_many :draft_picks, -> { order(:overall_number) }, class_name: "EspnDraftPick", dependent: :destroy, inverse_of: :espn_season
  has_many :team_seasons, -> { order(:espn_team_id) }, class_name: "EspnTeamSeason", dependent: :destroy, inverse_of: :espn_season

  validates :season, numericality: { only_integer: true, greater_than: 2000 }, uniqueness: { scope: :league_id }
  validates :name, :synced_at, presence: true
  validates :team_count, numericality: { only_integer: true, in: 1..20 }

  scope :newest_first, -> { order(season: :desc) }

  def rounds
    draft_picks.maximum(:round).to_i
  end

  def position_counts
    draft_picks.group(:position).count.sort_by { |position, count| [ -count, position.to_s ] }.to_h
  end
end
