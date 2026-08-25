# frozen_string_literal: true

module Drafts
  class BroadcastUndoPick
    def initialize(pick)
      @pick = pick
    end

    def call
      draft.broadcast_action_later_to(draft, action: :refresh_frame, target: header_target, render: false)
      draft.broadcast_action_later_to(draft, action: :refresh_frame, target: content_target, render: false)
      draft.broadcast_replace_later_to(
        draft,
        target: "flash",
        html: Components::FlashRegion.new(messages: { notice: "Undid #{pick.team.name}'s pick of #{pick.player.name}. The clock is paused." }).call
      )
    end

    private

    attr_reader :pick

    delegate :draft, to: :pick

    def header_target = "draft-#{draft.public_id}-header"
    def content_target = "draft-#{draft.public_id}-content"
  end
end
