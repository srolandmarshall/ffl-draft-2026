# frozen_string_literal: true

require "test_helper"

class Drafts::BroadcastPickTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "queues targeted updates for room frames and drafted player rows" do
    draft = drafts(:one)
    pick = draft.picks.create!(team: teams(:one), player: players(:one), round: 1, overall_number: 1, elapsed_seconds: 12)

    clear_enqueued_jobs
    assert_enqueued_with(job: Turbo::Streams::ActionBroadcastJob) do
      Drafts::BroadcastPick.new(pick).call
    end
  end

  test "queues five targeted live updates for an in-progress pick" do
    draft = drafts(:one)
    pick = draft.picks.create!(team: teams(:one), player: players(:one), round: 1, overall_number: 1, elapsed_seconds: 12)
    clear_enqueued_jobs

    assert_enqueued_jobs 5 do
      Drafts::BroadcastPick.new(pick).call
    end
  end

  test "renders recent picks and board without the application layout" do
    draft = drafts(:one)
    pick = draft.picks.create!(team: teams(:one), player: players(:one), round: 1, overall_number: 1, elapsed_seconds: 12)
    broadcast = Drafts::BroadcastPick.new(pick)

    recent_picks_html = broadcast.send(:recent_picks_html)
    board_html = broadcast.send(:board_html)

    assert_includes recent_picks_html, "draft-#{draft.public_id}-recent-picks"
    assert_includes board_html, "draft-#{draft.public_id}-board-content"
    refute_includes recent_picks_html, "<html"
    refute_includes recent_picks_html, "Draft home"
    refute_includes board_html, "<html"
    refute_includes board_html, "Draft home"
  end
end
