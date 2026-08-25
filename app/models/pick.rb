class Pick < ApplicationRecord
  belongs_to :draft
  belongs_to :team
  belongs_to :player

  validates :round, :overall_number, numericality: { only_integer: true, greater_than: 0 }
  validates :elapsed_seconds, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :overall_number, uniqueness: { scope: :draft_id }
  validates :player_id, uniqueness: { scope: :draft_id, message: "has already been drafted" }

  after_create_commit -> { Drafts::BroadcastPick.new(self).call }
end
