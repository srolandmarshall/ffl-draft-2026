# frozen_string_literal: true

require "test_helper"

class Components::Drafts::ResultsTest < ActiveSupport::TestCase
  test "renders results actions for a completed draft" do
    draft = drafts(:one)
    draft.update!(status: :complete)
    html = ApplicationController.renderer.render(
      Components::Drafts::Results.new(draft:, picks: draft.picks, pick_elapsed_seconds: {}, current_user: users(:commissioner))
    )

    assert_includes html, "Draft results"
    assert_includes html, "Export CSV"
    assert_includes html, "Export JSON"
  end

  test "commissioner can reopen a completed draft by undoing its latest pick" do
    draft = drafts(:one)
    pick = draft.picks.create!(team: teams(:one), player: players(:one), round: 1, overall_number: 1)
    draft.update!(status: :complete)

    html = ApplicationController.renderer.render(
      Components::Drafts::Results.new(draft:, picks: [ pick ], pick_elapsed_seconds: {}, current_user: users(:commissioner))
    )

    assert_includes html, "Undo last pick"
    assert_includes html, draft_pick_path(draft.public_id, pick)
  end
end
