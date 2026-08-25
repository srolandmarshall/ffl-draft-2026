# frozen_string_literal: true

require "test_helper"

class Components::Drafts::HeaderTest < ActiveSupport::TestCase
  test "renders the draft identity and roster summary" do
    html = Components::Drafts::Header.new(drafts(:one)).call

    assert_includes html, drafts(:one).name
    assert_includes html, "Status: live"
    assert_includes html, "QB 1"
  end
end
