# frozen_string_literal: true

module Drafts
  class BroadcastAnnouncement
    def self.pick(pick)
      new(
        draft: pick.draft,
        attributes: {
          "kind" => "pick",
          "team-name" => pick.team.name,
          "player-name" => pick.player.name,
          "logo-url" => ApplicationController.helpers.nfl_team_logo_url(pick.player.pro_team),
          "round" => pick.round,
          "pick" => ((pick.overall_number - 1) % pick.draft.draft_entries.size) + 1,
          "overall" => pick.overall_number
        }
      )
    end

    def self.message(draft:, message:)
      new(draft:, attributes: { "kind" => "message", "message" => message })
    end

    def initialize(draft:, attributes:)
      @draft = draft
      @attributes = attributes
    end

    def call
      @draft.broadcast_action_to(
        @draft,
        action: :draft_pick_announcement,
        target: "draft-#{@draft.public_id}-pick-ticker",
        attributes: @attributes,
        render: false
      )
    end
  end
end
