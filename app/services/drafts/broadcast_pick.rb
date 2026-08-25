# frozen_string_literal: true

module Drafts
  class BroadcastPick
    def initialize(pick)
      @pick = pick
    end

    def call
      if draft.complete?
        draft.broadcast_action_to(
          draft,
          action: :visit,
          target: Rails.application.routes.url_helpers.draft_path(draft.public_id),
          render: false
        )
        return
      end

      draft.broadcast_replace_later_to(
        draft,
        target: recent_picks_target,
        html: recent_picks_html
      )
      draft.broadcast_replace_later_to(
        draft,
        target: board_cell_target(pick.overall_number),
        html: board_cell_html(pick.overall_number, pick: broadcast_pick)
      )
      broadcast_next_cell
      draft.broadcast_action_later_to(
        draft,
        action: :refresh_frame,
        target: players_target,
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
      draft.broadcast_action_later_to(draft, action: :refresh_frame, target: team_roster_target, render: false)
      draft.broadcast_replace_later_to(
        draft,
        target: "flash",
        html: Components::FlashRegion.new(messages: { notice: "#{pick.team.name} has picked #{pick.player.name} (#{pick.player.position})" }).call
      )
    end

    private

    attr_reader :pick

    delegate :draft, to: :pick

    def recent_pick_window
      @recent_pick_window ||= draft.picks.includes(:team, player: { headshot_attachment: :blob }).last(5)
    end

    def pick_elapsed_seconds
      recent_pick_window.each_with_index.to_h do |current_pick, index|
        previous_pick_at = index.zero? ? draft.started_at : recent_pick_window[index - 1].created_at
        elapsed = current_pick.elapsed_seconds || (previous_pick_at ? (current_pick.created_at - previous_pick_at).round : 0)
        [ current_pick.id.to_s, elapsed ]
      end
    end

    def recent_picks_target = "draft-#{draft.public_id}-recent-picks"
    def board_cell_target(overall_number) = "draft-#{draft.public_id}-board-cell-#{overall_number}"
    def clock_target = "draft-#{draft.public_id}-clock"
    def content_target = "draft-#{draft.public_id}-content"
    def players_target = "draft-#{draft.public_id}-players"
    def team_roster_target = "draft-#{draft.public_id}-team-roster"
    def room_target = ActionView::RecordIdentifier.dom_id(draft, :room)
    def current_team = @current_team ||= draft.current_team

    def recent_picks_html
      ApplicationController.renderer.render(
        Components::Drafts::RecentPicks.new(
          draft:,
          picks: recent_pick_window.last(4),
          pick_elapsed_seconds:,
          pick_count: pick.overall_number
        ),
        layout: false
      )
    end

    def board_cell_html(overall_number, pick: nil)
      ApplicationController.renderer.render(
        Components::Drafts::BoardCell.new(
          draft:,
          team: draft.team_for_overall_number(overall_number),
          overall_number:,
          pick:,
          elapsed_seconds: pick&.elapsed_seconds.to_i,
          next_overall_number: self.pick.overall_number + 1
        ),
        layout: false
      )
    end

    def broadcast_pick
      @broadcast_pick ||= draft.picks.includes(:team, player: { headshot_attachment: :blob }).find(pick.id)
    end

    def broadcast_next_cell
      next_overall_number = pick.overall_number + 1
      return if next_overall_number > draft.total_picks

      draft.broadcast_replace_later_to(
        draft,
        target: board_cell_target(next_overall_number),
        html: board_cell_html(next_overall_number)
      )
    end
  end
end
