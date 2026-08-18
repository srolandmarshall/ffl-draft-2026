class DraftEntry < ApplicationRecord
  belongs_to :draft
  belongs_to :team

  validates :position, numericality: { only_integer: true, greater_than: 0 }, uniqueness: { scope: :draft_id }
  validates :team_id, uniqueness: { scope: :draft_id }
  validate :team_belongs_to_league

  private

  def team_belongs_to_league
    errors.add(:team, "must belong to the draft's league") if draft && team && draft.league_id != team.league_id
  end
end
