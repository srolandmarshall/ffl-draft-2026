# frozen_string_literal: true

require "test_helper"

class Components::Drafts::PickTickerTest < ActiveSupport::TestCase
  test "renders an initially hidden live ticker with a stable stream target" do
    draft = drafts(:one)

    html = Components::Drafts::PickTicker.new(draft:).call

    assert_includes html, %(id="draft-#{draft.public_id}-pick-ticker")
    assert_includes html, 'data-controller="draft-pick-ticker"'
    assert_includes html, "draft:pick-announcement->draft-pick-ticker#enqueue"
    assert_includes html, 'role="status"'
    assert_includes html, 'aria-live="polite"'
    assert_includes html, "hidden"
  end
end
