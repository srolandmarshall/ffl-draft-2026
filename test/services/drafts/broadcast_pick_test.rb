# frozen_string_literal: true

require "test_helper"

class Drafts::BroadcastPickTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "broadcasts targeted updates immediately including a player-list refresh" do
    draft = drafts(:one)
    pick = draft.picks.create!(team: teams(:one), player: players(:one), round: 1, overall_number: 1, elapsed_seconds: 12)

    clear_enqueued_jobs
    broadcasts = capture_broadcasts(draft.to_gid_param) do
      assert_no_enqueued_jobs { Drafts::BroadcastPick.new(pick).call }
    end

    assert broadcasts.any? { |payload| payload.include?(%(<turbo-stream action="refresh_frame" target="draft-#{draft.public_id}-players">)) }
  end

  test "broadcasts all eight targeted updates without a job worker" do
    draft = drafts(:one)
    pick = draft.picks.create!(team: teams(:one), player: players(:one), round: 1, overall_number: 1, elapsed_seconds: 12)
    clear_enqueued_jobs

    assert_broadcasts(draft.to_gid_param, 8) do
      assert_no_enqueued_jobs { Drafts::BroadcastPick.new(pick).call }
    end
  end

  test "a completed draft broadcasts one top-level visit without stale frame updates" do
    draft = drafts(:one)
    pick = draft.picks.create!(team: teams(:one), player: players(:one), round: 1, overall_number: 1, elapsed_seconds: 12)
    draft.update!(status: :complete, completed_at: Time.current)
    clear_enqueued_jobs

    assert_no_enqueued_jobs do
      assert_broadcast_on(draft.to_gid_param, '<turbo-stream action="visit" target="/drafts/sunday-draft"><template></template></turbo-stream>') do
        Drafts::BroadcastPick.new(pick).call
      end
    end
  end

  test "renders recent picks and the changed board cells without the application layout" do
    draft = drafts(:one)
    pick = draft.picks.create!(team: teams(:one), player: players(:one), round: 1, overall_number: 1, elapsed_seconds: 12)
    broadcast = Drafts::BroadcastPick.new(pick)

    recent_picks_html = broadcast.send(:recent_picks_html)
    picked_cell_html = broadcast.send(:board_cell_html, pick.overall_number, pick: broadcast.send(:broadcast_pick))
    next_cell_html = broadcast.send(:board_cell_html, pick.overall_number + 1)

    assert_includes recent_picks_html, "draft-#{draft.public_id}-recent-picks"
    assert_includes picked_cell_html, "draft-#{draft.public_id}-board-cell-1"
    assert_includes picked_cell_html, players(:one).name
    assert_includes next_cell_html, "draft-#{draft.public_id}-board-cell-2"
    refute_includes recent_picks_html, "<html"
    refute_includes recent_picks_html, "Draft home"
    refute_includes picked_cell_html, "<html"
    refute_includes next_cell_html, "<html"
    assert_operator picked_cell_html.bytesize + next_cell_html.bytesize, :<, 10_000
  end

  test "renders a preloaded board without additional queries" do
    draft = Draft.includes(draft_entries: :team).find(drafts(:one).id)
    picks = draft.picks.includes(:team, player: { headshot_attachment: :blob }).to_a
    queries = []
    subscriber = lambda do |_name, _start, _finish, _id, payload|
      queries << payload[:sql] unless payload[:name] == "SCHEMA" || payload[:cached]
    end

    token = ActiveSupport::Notifications.subscribe("sql.active_record", subscriber)
    ApplicationController.renderer.render(
      Components::Drafts::Board.new(draft:, picks:, pick_elapsed_seconds: {}),
      layout: false
    )
    ActiveSupport::Notifications.unsubscribe(token)

    assert_empty queries, "Expected the preloaded board to avoid SQL, but ran:\n#{queries.join("\n")}"
  ensure
    ActiveSupport::Notifications.unsubscribe(token) if token
  end
end
