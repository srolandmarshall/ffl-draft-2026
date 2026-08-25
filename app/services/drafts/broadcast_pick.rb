# frozen_string_literal: true

module Drafts
  class BroadcastPick
    def initialize(pick)
      @pick = pick
    end

    def call
      draft.broadcast_replace_later_to(
        draft,
        target: recent_picks_target,
        html: recent_picks_html
      )
      draft.broadcast_replace_later_to(
        draft,
        target: board_target,
        html: board_html
      )
      draft.broadcast_action_later_to(
        draft,
        action: :remove,
        targets: "[data-draft-player-id='#{pick.player_id}']",
        render: false
      )
      draft.broadcast_action_to(
        draft,
        action: :draft_turn,
        target: room_target,
        attributes: {
          "team-id" => current_team&.id,
          "team-name" => current_team&.name,
          "round" => draft.current_round,
          "pick" => draft.next_overall_number
        },
        render: false
      )
      draft.broadcast_action_later_to(draft, action: :refresh_frame, target: clock_target, render: false)
      draft.broadcast_replace_later_to(
        draft,
        target: "flash",
        html: Components::FlashRegion.new(messages: { notice: "#{pick.team.name} has picked #{pick.player.name} (#{pick.player.position})" }).call
      )
      draft.broadcast_action_later_to(draft, action: :refresh_frame, target: content_target) if draft.complete?
    end

    private

    attr_reader :pick

    delegate :draft, to: :pick

    def picks
      @picks ||= draft.picks.includes(:team, player: { headshot_attachment: :blob }).to_a
    end

    def pick_elapsed_seconds
      started_at = draft.started_at
      picks.to_h do |current_pick|
        elapsed = current_pick.elapsed_seconds || (started_at ? (current_pick.created_at - started_at).round : 0)
        started_at = current_pick.created_at
        [ current_pick.id.to_s, elapsed ]
      end
    end

    def recent_picks_target = "draft-#{draft.public_id}-recent-picks"
    def board_target = "draft-#{draft.public_id}-board-content"
    def clock_target = "draft-#{draft.public_id}-clock"
    def content_target = "draft-#{draft.public_id}-content"
    def room_target = ActionView::RecordIdentifier.dom_id(draft, :room)
    def current_team = @current_team ||= draft.current_team

    def recent_picks_html
      ApplicationController.renderer.render(
        Components::Drafts::RecentPicks.new(draft:, picks:, pick_elapsed_seconds:),
        layout: false
      )
    end

    def board_html
      ApplicationController.renderer.render(
        Components::Drafts::Board.new(draft:, picks:, pick_elapsed_seconds:),
        layout: false
      )
    end
  end
end
