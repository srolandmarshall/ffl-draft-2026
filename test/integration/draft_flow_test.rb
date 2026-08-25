require "test_helper"

class DraftFlowTest < ActionDispatch::IntegrationTest
  test "shared draft room renders before team selection" do
    attach_headshot(players(:one))
    sign_in_as users(:member)
    get draft_path(drafts(:one).public_id)

    assert_response :success
    assert_select "h1", drafts(:one).name
    assert_select "turbo-frame#draft-sunday-draft-header"
    assert_select "turbo-frame#draft-sunday-draft-content"
    assert_select "turbo-frame#draft-sunday-draft-room"
    assert_select "p", text: /You're up now/
    assert_select "a", text: /Export/, count: 0
    assert_select "[data-controller='pick-timer'][data-pick-timer-paused-value='false']"
    assert_select "p", text: /Recent picks/
    assert_select "nav[aria-label='Draft room view'] a", count: 2
    assert_select "nav[aria-label='Draft room view'] span", "Draft board"
    assert_select "th", "2025 production"
    assert_select "th", "2025 FP"
    assert_equal [ "Player", "Bye", "2025 FP", "Games", "TDs", "2025 production", "Action" ], css_select("thead th").map { |header| header.text.strip }
    assert_select "th", text: "ADP", count: 0
    assert_select "span", "Rookie"
    assert_select "dt", text: "YDS", minimum: 2
    assert_select "dt", text: "YPG", minimum: 2
    assert_select "dd", text: "4,200", minimum: 2
    assert_select "td", text: "17", minimum: 1
    assert_select "td", text: /333.3/
    assert_select "p", text: /ESPN scoring rules/
    assert_select "img[src*='/rails/active_storage/'][loading='lazy']", minimum: 2
    team_logo_url = ApplicationController.helpers.nfl_team_logo_url(players(:one).pro_team)
    assert_select "img[src='#{team_logo_url}'][title='#{players(:one).pro_team}']", minimum: 2
    assert_select "[data-controller='draft-filter']"
    assert_select "[data-draft-filter-target='all'][aria-pressed='true']", text: "All"
    assert_select "[data-draft-filter-target='position']", count: Player::POSITIONS.size
    assert_select "[data-draft-player-id='#{players(:one).id}']", minimum: 1
    assert_select "#flash"
    room_id = ActionView::RecordIdentifier.dom_id(drafts(:one), :room)
    assert_select "##{room_id}[data-controller='draft-pick'][data-action='draft:turn->draft-pick#turnChanged'][data-draft-pick-selected-team-id-value='#{teams(:one).id}'][data-draft-pick-commissioner-value='false']"
    assert_select "form", minimum: 1 do
      assert_select "button[type='button'][data-action='draft-pick#prepare']", "Draft"
      assert_select "button[type='submit'][data-draft-pick-target='confirm']", "✓"
      assert_select "button[type='button'][data-action='draft-pick#cancel']", "×"
    end
  end

  test "player list is limited to 36 and deep players remain searchable" do
    40.times do |index|
      Player.create!(
        name: format("Depth Player %02d", index + 1),
        position: "WR",
        pro_team: "ATL",
        adp: index + 1
      )
    end
    deep_player = Player.create!(name: "Deep Search Sleeper", position: "TE", pro_team: "SEA", adp: 999)
    sign_in_as users(:member)

    get draft_path(drafts(:one).public_id)

    assert_response :success
    rendered_player_ids = css_select("[data-draft-player-id]").map { |element| element["data-draft-player-id"] }.uniq
    assert_equal 36, rendered_player_ids.size
    refute_includes rendered_player_ids, deep_player.id.to_s

    get players_draft_path(drafts(:one).public_id), params: { query: "search sleeper" }

    assert_response :success
    assert_select "turbo-frame#draft-sunday-draft-players"
    assert_select "[data-draft-player-id='#{deep_player.id}']", count: 2
    assert_select "input[name='query'][value='search sleeper']"
  end

  test "player list backfills to 36 after players are drafted" do
    40.times do |index|
      Player.create!(name: "Available Player #{index + 1}", position: "WR", pro_team: "ATL", adp: index + 1)
    end
    draft = drafts(:one)
    drafted_player = Player.by_adp.first
    draft.picks.create!(team: teams(:one), player: drafted_player, round: 1, overall_number: 1)
    sign_in_as users(:member)

    get players_draft_path(draft.public_id)

    assert_response :success
    rendered_player_ids = css_select("[data-draft-player-id]").map { |element| element["data-draft-player-id"] }.uniq
    assert_equal 36, rendered_player_ids.size
    refute_includes rendered_player_ids, drafted_player.id.to_s
  end

  test "position and team filters search beyond the default player window" do
    36.times do |index|
      Player.create!(name: "Window Player #{index + 1}", position: "RB", pro_team: "BUF", adp: index + 1)
    end
    deep_player = Player.create!(name: "Deep Filter Sleeper", position: "TE", pro_team: "SEA", adp: 999)
    sign_in_as users(:member)

    get players_draft_path(drafts(:one).public_id), params: { positions: [ "TE" ], teams: [ "SEA" ] }

    assert_response :success
    assert_select "[data-draft-player-id='#{deep_player.id}']", count: 2
    assert_select "input[name='positions[]'][value='TE'][checked]"
    assert_select "input[name='teams[]'][value='SEA'][checked]"
    assert_select "turbo-frame[data-player-refresh-url*='positions%5B%5D=TE'][data-player-refresh-url*='teams%5B%5D=SEA']"
  end

  test "draft room has a secondary board view" do
    sign_in_as users(:member)
    get draft_path(drafts(:one).public_id, view: "board")

    assert_response :success
    assert_select "h2", "Draft board"
    assert_select "div[title='#{teams(:one).name}']", text: teams(:one).abbreviation
    assert_select "[data-draft-board-row]", count: drafts(:one).rounds
    assert_select "[aria-label='#{teams(:one).name}, your team']", text: teams(:one).abbreviation
    assert_select "[data-draft-board-team-id='#{teams(:one).id}']", count: drafts(:one).rounds do |cells|
      cells.each { |cell| assert_includes cell["class"], "bg-lime-300/10" }
    end
    assert_select "nav[aria-label='Draft room view'] span", "Player list"
  end

  test "commissioner without a team sees an unpersonalized board" do
    sign_in_as users(:commissioner)

    get draft_path(drafts(:one).public_id, view: "board")

    assert_response :success
    assert_select "[aria-label$=', your team']", count: 0
    assert_select "[data-draft-board-team-id].bg-lime-300\\/10", count: 0
  end

  test "completed picks retain their elapsed time in the log and board" do
    draft = drafts(:one)
    draft.update!(started_at: Time.zone.parse("2026-08-14 12:00:00"))
    pick = draft.picks.create!(
      team: teams(:one),
      player: players(:one),
      round: 1,
      overall_number: 1,
      created_at: Time.zone.parse("2026-08-14 12:01:01")
    )
    attach_headshot(players(:one))
    sign_in_as users(:member)

    get draft_path(draft.public_id, view: "board")

    assert_response :success
    assert_select ".text-yellow-300", text: "1:01", minimum: 2
    assert_select "li", text: /#{teams(:one).abbreviation} · R1 · Pick 1/
    assert_select "[data-recent-pick] img[src*='/rails/active_storage/']", count: 1
    assert_select "[data-draft-board-pick='true'] img[src*='/rails/active_storage/']", count: 1
    assert_select "[data-pick-timer-elapsed-value]"
  end

  test "commissioner pauses and resumes the current pick timer" do
    draft = drafts(:one)
    draft.update!(started_at: Time.zone.parse("2026-08-14 12:00:00"))
    sign_in_as users(:commissioner)

    travel_to Time.zone.parse("2026-08-14 12:00:30") do
      patch draft_pick_timer_path(draft.public_id), params: { state: "pause" }
    end
    assert_redirected_to draft_path(draft.public_id)
    assert_equal Time.zone.parse("2026-08-14 12:00:30"), draft.reload.pick_timer_paused_at

    get draft_path(draft.public_id)
    assert_select "[data-pick-timer-paused-value='true'][data-pick-timer-elapsed-value='30']"
    assert_select "button", "Resume"

    travel_to Time.zone.parse("2026-08-14 12:02:30") do
      patch draft_pick_timer_path(draft.public_id), params: { state: "resume" }
    end
    assert_nil draft.reload.pick_timer_paused_at
    assert_equal 120, draft.pick_timer_paused_seconds
  end

  test "regular users cannot pause the timer" do
    draft = drafts(:one)
    sign_in_as users(:member)

    patch draft_pick_timer_path(draft.public_id), params: { state: "pause" }

    assert_redirected_to root_path
    assert_nil draft.reload.pick_timer_paused_at
  end

  test "assigned manager makes its pick" do
    draft = drafts(:one)
    sign_in_as users(:member)

    assert_difference("Pick.count", 1) do
      post draft_picks_path(draft.public_id), params: { player_id: players(:one).id }
    end
    assert_redirected_to draft_path(draft.public_id)
    follow_redirect!
    assert_select "body", text: /#{teams(:one).name} has picked #{players(:one).name} \(#{players(:one).position}\)/
  end

  test "commissioner makes a pick for the team on the clock" do
    draft = drafts(:one)
    expected_team = draft.current_team
    sign_in_as users(:commissioner)

    get draft_path(draft.public_id)
    assert_response :success
    assert_select "form button:not([disabled])", text: "Draft", minimum: 1

    assert_difference("Pick.count", 1) do
      post draft_picks_path(draft.public_id), params: { player_id: players(:one).id }
    end

    assert_equal expected_team, Pick.last.team
    assert_redirected_to draft_path(draft.public_id)
  end

  test "commissioner undoes the latest pick" do
    draft = drafts(:one)
    pick = draft.picks.create!(team: teams(:one), player: players(:one), round: 1, overall_number: 1)
    sign_in_as users(:commissioner)

    assert_difference("Pick.count", -1) do
      delete draft_pick_path(draft.public_id, pick)
    end

    assert_redirected_to draft_path(draft.public_id)
    assert_predicate draft.reload, :pick_timer_paused?
  end

  test "regular users cannot undo a pick" do
    draft = drafts(:one)
    pick = draft.picks.create!(team: teams(:one), player: players(:one), round: 1, overall_number: 1)
    sign_in_as users(:member)

    assert_no_difference("Pick.count") do
      delete draft_pick_path(draft.public_id, pick)
    end

    assert_redirected_to root_path
  end

  test "draft export is available as CSV" do
    sign_in_as users(:member)
    get draft_export_path(drafts(:one).public_id, format: :csv)

    assert_response :success
    assert_equal "text/csv", response.media_type
  end

  test "completed draft shows exports on its results page" do
    draft = drafts(:one)
    draft.update!(status: :complete, completed_at: Time.current)
    sign_in_as users(:member)

    get draft_path(draft.public_id)

    assert_response :success
    assert_select "h2", "Draft results"
    assert_select "a", "Export CSV"
    assert_select "a", "Export JSON"
    assert_select "h2", "Draft board"
  end

  test "commissioner dashboard renders" do
    sign_in_as users(:commissioner)
    get admin_root_path

    assert_response :success
    assert_select "h1", "League admin"
  end

  test "commissioner can open the sourced player tools" do
    sign_in_as users(:commissioner)
    get admin_players_path
    assert_response :success
    assert_select "th", "ADP"

    get new_admin_adp_import_path
    assert_response :success
    assert_select "h1", "Refresh ADP"
  end

  private

  def attach_headshot(player)
    player.headshot.attach(io: StringIO.new("headshot"), filename: "headshot.png", content_type: "image/png")
  end
end
