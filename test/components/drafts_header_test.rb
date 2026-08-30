# frozen_string_literal: true

require "test_helper"

class Components::Drafts::HeaderTest < ActiveSupport::TestCase
  test "renders the draft identity and roster summary" do
    html = Components::Drafts::Header.new(drafts(:one)).call

    assert_includes html, drafts(:one).name
    assert_includes html, "Status: live"
    assert_includes html, "QB 1"
  end

  test "shows an export csv button once the draft is complete" do
    draft = drafts(:one)
    draft.update!(status: :complete)

    html = ApplicationController.renderer.render(Components::Drafts::Header.new(draft))

    assert_includes html, "Export CSV"
    assert_includes html, "Export XLSX"
    assert_includes html, "Status: complete"
  end

  test "hides the export csv button while the draft is live" do
    html = Components::Drafts::Header.new(drafts(:one)).call

    refute_includes html, "Export CSV"
    refute_includes html, "Export XLSX"
  end
end
