require "test_helper"

module Drafts
  class UndoPickTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    setup do
      @draft = drafts(:one)
      @draft.update!(started_at: 5.minutes.ago, completed_at: nil)
      @first_pick = @draft.picks.create!(team: teams(:one), player: players(:one), round: 1, overall_number: 1, elapsed_seconds: 30)
      @latest_pick = @draft.picks.create!(team: teams(:one), player: players(:two), round: 2, overall_number: 2, elapsed_seconds: 45)
      clear_enqueued_jobs
    end

    test "removes only the latest pick and pauses a fresh clock" do
      travel 2.minutes do
        UndoPick.new(draft: @draft, pick: @latest_pick).call

        assert_not Pick.exists?(@latest_pick.id)
        assert Pick.exists?(@first_pick.id)
        assert_predicate @draft.reload, :live?
        assert_predicate @draft, :pick_timer_paused?
        assert_equal 0, @draft.current_pick_elapsed_seconds
      end
    end

    test "rejects undoing an older pick" do
      error = assert_raises(UndoPick::InvalidUndo) do
        UndoPick.new(draft: @draft, pick: @first_pick).call
      end

      assert_equal "Only the latest pick can be undone.", error.message
      assert_equal 2, @draft.picks.count
    end

    test "reopens a completed draft" do
      @draft.update!(status: :complete, completed_at: Time.current)

      UndoPick.new(draft: @draft, pick: @latest_pick).call

      assert_predicate @draft.reload, :live?
      assert_nil @draft.completed_at
    end
  end
end
