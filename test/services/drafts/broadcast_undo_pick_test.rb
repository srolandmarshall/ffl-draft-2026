# frozen_string_literal: true

require "test_helper"

class Drafts::BroadcastUndoPickTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "queues personalized frame refreshes and an undo notice" do
    draft = drafts(:one)
    pick = draft.picks.create!(team: teams(:one), player: players(:one), round: 1, overall_number: 1, elapsed_seconds: 12)
    clear_enqueued_jobs

    assert_enqueued_jobs 3 do
      Drafts::BroadcastUndoPick.new(pick).call
    end
  end
end
