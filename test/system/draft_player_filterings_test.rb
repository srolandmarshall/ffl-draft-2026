require "application_system_test_case"

class DraftPlayerFilteringsTest < ApplicationSystemTestCase
  test "searching, selecting filters, and clearing replace the player list in the browser" do
    draft = drafts(:one)
    40.times do |index|
      Player.create!(name: "Window Player #{index + 1}", position: "WR", pro_team: "ATL", ranking: index + 1)
    end
    sleeper = Player.create!(name: "Deep Search Sleeper", position: "TE", pro_team: "SEA", ranking: 999)
    sign_in_in_browser(users(:member))

    visit draft_path(draft.public_id)
    assert_no_selector "[data-draft-player-id='#{sleeper.id}']"

    fill_in "Search players…", with: "search sleeper"
    assert_selector "[data-draft-player-id='#{sleeper.id}']"

    click_button "Clear filters"
    assert_no_selector "[data-draft-player-id='#{sleeper.id}']"

    all("input[name='positions[]'][value='TE']", visible: :all).last.check(allow_label_click: true)
    assert_selector "[data-draft-player-id='#{sleeper.id}']"

    team_filter = "#draft-#{draft.public_id}-players-team-filter"
    find("#{team_filter} > summary").click
    assert_selector "#{team_filter}[open]"
    find("#{team_filter} input[name='teams[]'][value='SEA']").check
    assert_selector "[data-draft-player-id='#{sleeper.id}']"

    find("#{team_filter} > summary").click
    assert_no_selector "#{team_filter}[open]"
    click_button "Clear filters"
    assert_no_selector "[data-draft-player-id='#{sleeper.id}']"
  end
end
