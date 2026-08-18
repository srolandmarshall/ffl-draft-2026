# frozen_string_literal: true

require "test_helper"

class Components::Drafts::ResultsTest < ActiveSupport::TestCase
  test "renders results actions for a completed draft" do
    draft = drafts(:one)
    draft.update!(status: :complete)
    html = ApplicationController.renderer.render(
      Components::Drafts::Results.new(draft:, picks: draft.picks, pick_elapsed_seconds: {})
    )

    assert_includes html, "Draft results"
    assert_includes html, "Export CSV"
    assert_includes html, "Export JSON"
  end
end
