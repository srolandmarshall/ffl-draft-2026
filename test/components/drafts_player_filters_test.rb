# frozen_string_literal: true

require "test_helper"

class Components::Drafts::PlayerFiltersTest < ActiveSupport::TestCase
  test "renders search, position, and team filter targets" do
    players = [ players(:one), players(:two) ]
    html = ApplicationController.renderer.render(Components::Drafts::PlayerFilters.new(players:))

    assert_includes html, "Search players"
    assert_includes html, "data-draft-filter-target=\"position\""
    assert_includes html, "data-draft-filter-target=\"team\""
    assert_includes html, "All teams"
  end
end
