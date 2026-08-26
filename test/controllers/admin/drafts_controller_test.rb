# frozen_string_literal: true

require "test_helper"

class Admin::DraftsControllerTest < ActionDispatch::IntegrationTest
  test "commissioner broadcasts a ticker message to a live draft" do
    league = leagues(:one)
    draft = drafts(:one)
    draft.update!(status: :live, started_at: Time.current)
    sign_in_as users(:commissioner)

    assert_broadcast_on(draft.to_gid_param, %(<turbo-stream kind="message" message="Trade offers are open" action="draft_pick_announcement" target="draft-#{draft.public_id}-pick-ticker"><template></template></turbo-stream>)) do
      post broadcast_message_admin_league_draft_path(league, draft), params: { message: "Trade offers are open" }
    end

    assert_response :no_content
  end

  test "commissioner must wait five seconds between broadcasts" do
    league = leagues(:one)
    draft = drafts(:one)
    draft.update!(status: :live, started_at: Time.current)
    sign_in_as users(:commissioner)

    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    begin
      post broadcast_message_admin_league_draft_path(league, draft), params: { message: "First message" }
      assert_response :no_content

      assert_no_broadcasts(draft.to_gid_param) do
        post broadcast_message_admin_league_draft_path(league, draft), params: { message: "Too soon" }
      end
      assert_response :too_many_requests
    ensure
      Rails.cache = original_cache
    end
  end

  test "broadcast messages must be present and short" do
    league = leagues(:one)
    draft = drafts(:one)
    sign_in_as users(:commissioner)

    post broadcast_message_admin_league_draft_path(league, draft), params: { message: " " }

    assert_redirected_to draft_path(draft.public_id)
    assert_equal "Broadcast message cannot be blank.", flash[:alert]
  end

  test "messages cannot be broadcast outside a live draft" do
    league = leagues(:one)
    draft = drafts(:one)
    draft.update!(status: :setup, started_at: nil)
    sign_in_as users(:commissioner)

    post broadcast_message_admin_league_draft_path(league, draft), params: { message: "This should not appear" }

    assert_redirected_to draft_path(draft.public_id)
    assert_equal "Messages can only be broadcast while the draft is live.", flash[:alert]
  end
end
