# frozen_string_literal: true

require "test_helper"

class DraftLiveUpdatesTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "two viewers converge on a pick without a full-page room response" do
    draft = drafts(:one)
    player = players(:one)
    member = open_session
    commissioner = open_session
    sign_in(member, users(:member))
    sign_in(commissioner, users(:commissioner))

    member.get draft_path(draft.public_id)
    commissioner.get draft_path(draft.public_id)
    assert_response_for member, 200
    assert_response_for commissioner, 200

    assert_difference("Pick.count", 1) do
      commissioner.post draft_picks_path(draft.public_id), params: { player_id: player.id }, headers: turbo_frame_headers("draft-#{draft.public_id}-room")
    end

    assert_equal 204, commissioner.response.status
    assert_empty commissioner.response.body

    member.get draft_path(draft.public_id)
    body = member.response.body
    assert_includes body, player.name
    assert_includes body, "#{draft.current_team.name}"
    refute_includes body, "data-draft-player-id=\"#{player.id}\""
    assert_includes body, "#{teams(:one).abbreviation} · R1 · Pick 1"
  end

  test "a stale viewer cannot draft a player selected by another viewer" do
    draft = drafts(:one)
    player = players(:one)
    member = open_session
    commissioner = open_session
    sign_in(member, users(:member))
    sign_in(commissioner, users(:commissioner))

    member.post draft_picks_path(draft.public_id), params: { player_id: player.id }
    assert_equal 302, member.response.status

    assert_no_difference("Pick.count") do
      commissioner.post draft_picks_path(draft.public_id), params: { player_id: player.id }
    end
    assert_equal 302, commissioner.response.status
    commissioner.follow_redirect!
    assert_match(/That player (?:was just selected|has already been drafted)/, commissioner.response.body)
  end

  test "the final pick visits the completed board at the top level" do
    draft = drafts(:one)
    draft.picks.create!(team: teams(:one), player: players(:one), round: 1, overall_number: 1)
    commissioner = open_session
    sign_in(commissioner, users(:commissioner))

    commissioner.post draft_picks_path(draft.public_id),
      params: { player_id: players(:two).id },
      headers: turbo_frame_headers("draft-#{draft.public_id}-room")

    assert_equal 200, commissioner.response.status
    assert_predicate draft.reload, :complete?
    assert_includes commissioner.response.body, '<turbo-stream action="visit" target="/drafts/sunday-draft">'
  end

  test "a stale pick submitted after completion visits the completed board" do
    draft = drafts(:one)
    draft.update!(status: :complete, completed_at: Time.current)
    commissioner = open_session
    sign_in(commissioner, users(:commissioner))

    assert_no_difference("Pick.count") do
      commissioner.post draft_picks_path(draft.public_id),
        params: { player_id: players(:one).id },
        headers: turbo_frame_headers("draft-#{draft.public_id}-room")
    end

    assert_equal 200, commissioner.response.status
    assert_includes commissioner.response.body, '<turbo-stream action="visit" target="/drafts/sunday-draft">'
    refute_includes commissioner.response.body, "Your email is not assigned"
  end

  test "pausing the timer broadcasts a clock-frame refresh" do
    draft = drafts(:one)
    sign_in_as users(:commissioner)
    clear_enqueued_jobs

    assert_enqueued_with(job: Turbo::Streams::ActionBroadcastJob) do
      patch draft_pick_timer_path(draft.public_id), params: { state: "pause" }
    end
  end

  private

  def sign_in(session, user)
    session.post session_path, params: { email: user.email }
    assert_equal 302, session.response.status
  end

  def assert_response_for(session, status)
    assert_equal status, session.response.status
  end

  def turbo_frame_headers(frame)
    { "HTTP_TURBO_FRAME" => frame, "HTTP_ACCEPT" => "text/vnd.turbo-stream.html, text/html" }
  end
end
