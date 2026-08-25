module Drafts
  class UndoPick
    class InvalidUndo < StandardError; end

    def initialize(draft:, pick:)
      @draft = draft
      @pick = pick
    end

    def call
      undone_pick = draft.with_lock do
        draft.picks.reset
        validate!
        pick.destroy!
        draft.picks.reset
        reset_draft_and_timer!
        pick
      end

      BroadcastUndoPick.new(undone_pick).call
      undone_pick
    end

    private

    attr_reader :draft, :pick

    def validate!
      raise InvalidUndo, "Only a live or completed draft can undo a pick." unless draft.live? || draft.complete?
      raise InvalidUndo, "There are no picks to undo." unless draft.picks.any?
      raise InvalidUndo, "Only the latest pick can be undone." unless draft.picks.last == pick
    end

    def reset_draft_and_timer!
      now = Time.current
      pick_started_at = draft.picks.last&.created_at || draft.started_at || now
      elapsed_before_pause = [ (now - pick_started_at).floor, 0 ].max

      draft.update!(
        status: :live,
        completed_at: nil,
        pick_timer_paused_at: now,
        pick_timer_paused_seconds: elapsed_before_pause
      )
    end
  end
end
