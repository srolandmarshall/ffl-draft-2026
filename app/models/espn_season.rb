class EspnSeason < ApplicationRecord
  TeamFinish = Data.define(:season, :name, :abbreviation, :rank)

  belongs_to :league
  has_many :draft_picks, -> { order(:overall_number) }, class_name: "EspnDraftPick", dependent: :destroy, inverse_of: :espn_season

  validates :season, numericality: { only_integer: true, greater_than: 2000 }, uniqueness: { scope: :league_id }
  validates :name, :synced_at, presence: true
  validates :team_count, numericality: { only_integer: true, in: 1..20 }

  scope :newest_first, -> { order(season: :desc) }

  def team_finish_for(owner_ids)
    identity = teams.find { |team| (Array(team["owner_ids"]) & Array(owner_ids)).any? }
    rank = identity&.fetch("final_rank", nil).to_i
    return if rank <= 0

    TeamFinish.new(
      season:,
      name: identity["name"],
      abbreviation: identity["abbreviation"],
      rank:
    )
  end

  def rounds
    draft_picks.maximum(:round).to_i
  end

  def position_counts
    draft_picks.group(:position).count.sort_by { |position, count| [ -count, position.to_s ] }.to_h
  end

  def settings_object
    DataSources::Espn::LeagueSettings.from_settings(settings)
  end
end
