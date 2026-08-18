module Drafts
  class MakePick
    class InvalidPick < StandardError; end

    def initialize(draft:, team:, player:)
      @draft = draft
      @team = team
      @player = player
    end

    def call
      draft.with_lock do
        draft.picks.reset
        draft.draft_entries.reset

        validate!
        elapsed_seconds = draft.current_pick_elapsed_seconds
        pick = draft.picks.create!(
          team: team,
          player: player,
          round: draft.current_round,
          overall_number: draft.next_overall_number,
          elapsed_seconds:
        )
        draft.update!(pick_timer_paused_at: nil, pick_timer_paused_seconds: 0)
        finish_draft_if_needed
        pick
      end
    rescue ActiveRecord::RecordNotUnique
      raise InvalidPick, "That player was just selected. Choose another player."
    end

    private

    attr_reader :draft, :team, :player

    def validate!
      raise InvalidPick, "The draft is not live." unless draft.live?
      raise InvalidPick, "This draft is already full." if draft.next_overall_number > draft.total_picks
      raise InvalidPick, "It is not #{team.name}'s turn." unless draft.current_team == team
      raise InvalidPick, "That player has already been drafted." if draft.picks.exists?(player: player)
      raise InvalidPick, "That player is not active." unless player.active?
    end

    def finish_draft_if_needed
      return unless draft.next_overall_number > draft.total_picks

      draft.update!(status: :complete, completed_at: Time.current)
    end
  end
end
