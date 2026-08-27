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
    assert_includes html, "id=\"draft-sunday-draft-players-query\""
    assert_includes html, "data-turbo-permanent"
    assert_includes html, "data-draft-filter-target=\"position\""
    assert_includes html, "name=\"positions[]\" value=\"QB\" checked"
    assert_includes html, "name=\"teams[]\" value=\"ATL\" checked"
    assert_includes html, "change->draft-filter#updateTeamSelection change->draft-filter#scheduleSelection"
    assert_includes html, "draft-filter#clearTeams"
    assert_includes html, "draft-filter#closeTeamMenu"
    assert_includes html, "aria-label=\"Close team filters\""
    assert_includes html, "draft-filter#clearFilters"
    assert_includes html, "input->draft-filter#scheduleSearch"
    assert_includes html, "name=\"positions[]\" value=\"QB\" checked class=\"peer sr-only\" data-draft-filter-target=\"position\" data-action=\"change->draft-filter#syncPositionSelection\""
    assert_includes html, "data-draft-filter-target=\"teamCount\""
    refute_includes html, "change->draft-filter#submit"
    assert_includes html, "value=\"Alex\""
    assert_includes html, "1 selected"
    assert_match(/<details id="draft-sunday-draft-players-position-filter" class="[^"]*w-fit[^"]*sm:hidden" data-turbo-permanent data-draft-filter-target="positionMenu"/, html)
    assert_includes html, "draft-filter#closePositionMenu"
    assert_match(/<details id="draft-sunday-draft-players-team-filter" class="[^"]*w-fit[^"]*" data-turbo-permanent data-draft-filter-target="teamMenu"/, html)
    assert_match(/class="[^"]*absolute[^"]*left-0[^"]*w-60[^"]*sm:left-auto[^"]*sm:right-0/, html)
    assert_match(/class="[^"]*sticky[^"]*top-0[^"]*z-10[^"]*bg-slate-950/, html)
    assert_match(/title="ATL"[^>]+size-7[^>]+bg-slate-400\/50/, html)
    assert_match(/title="BUF"[^>]+size-7[^>]+bg-slate-400\/50/, html)
  end

  test "only renders clear filters when a filter is active" do
    html = ApplicationController.renderer.render(
      Components::Drafts::PlayerFilters.new(
        draft: drafts(:one),
        players: [ players(:one) ],
        available_teams: [ "ATL" ],
        filters: { query: "", positions: [], teams: [] }
      )
    )

    refute_includes html, "draft-filter#clearFilters"
  end
end
