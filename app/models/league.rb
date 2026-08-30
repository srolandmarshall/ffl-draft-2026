class League < ApplicationRecord
  ROSTER_SLOT_ATTRIBUTES = %i[qb_slots rb_slots wr_slots te_slots flex_slots k_slots dst_slots bench_slots].freeze

  has_many :drafts, dependent: :destroy
  has_many :espn_seasons, dependent: :destroy
  has_many :espn_franchises, dependent: :destroy
  has_many :espn_team_seasons, through: :espn_seasons, source: :team_seasons
  has_many :league_player_scores, dependent: :destroy
  has_many :teams, dependent: :destroy

  enum :draft_type, { snake: 0, linear: 1 }

  before_validation :set_roster_size

  validates :name, presence: true
  validates :espn_league_id, format: { with: /\A\d+\z/, message: "must contain only numbers" }, uniqueness: { scope: :season }, allow_blank: true
  validates :season, numericality: { only_integer: true, greater_than: 2000 }
  validates :roster_size, numericality: { only_integer: true, in: 1..30 }
  validates(*ROSTER_SLOT_ATTRIBUTES, numericality: { only_integer: true, in: 0..20 })
  validates :ppr, inclusion: { in: [ 0, 0.5, 1 ], message: "must be 0, 0.5, or 1" }
  def draft_defaults
    attributes.slice(*Draft::ROSTER_SLOT_ATTRIBUTES.map(&:to_s), "ppr", "draft_type")
  end

  private

  def set_roster_size
    total = ROSTER_SLOT_ATTRIBUTES.sum { |attribute| public_send(attribute).to_i }
    self.roster_size = total if total.positive?
  end
end
