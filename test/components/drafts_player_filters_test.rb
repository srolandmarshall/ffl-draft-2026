# frozen_string_literal: true

require "test_helper"

class Components::Drafts::PlayerFiltersTest < ActiveSupport::TestCase
  test "renders search, position, and team filter targets" do
    players = [ players(:one), players(:two) ]
    html = ApplicationController.renderer.render(
      Components::Drafts::PlayerFilters.new(
        draft: drafts(:one),
        players:,
        available_teams: %w[ATL BUF],
        filters: { query: "Alex", positions: [ "QB" ], teams: [ "ATL" ] }
      )
    )

    assert_includes html, "Search players"
    assert_includes html, "action=\"/drafts/sunday-draft/players\""
    assert_includes html, "data-turbo-frame=\"draft-sunday-draft-players\""
    assert_includes html, "data-draft-filter-target=\"position\""
    assert_includes html, "name=\"positions[]\" value=\"QB\" checked"
    assert_includes html, "name=\"teams[]\" value=\"ATL\" checked"
    assert_includes html, "value=\"Alex\""
    assert_includes html, "1 selected"
  end
end
