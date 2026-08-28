require "application_system_test_case"

class DraftSimulationsTest < ApplicationSystemTestCase
  test "commissioner can run a full snake draft in the browser" do
    draft, players, expected_teams = rehearsal_draft
    sign_in_as_commissioner

    visit draft_path(draft.public_id)
    broadcast_message(draft, "Draft rehearsal is underway")

    draft_player(players.first)
    wait_for_pick_count(draft, 1)
    wait_for_player_to_leave_board(players.first)
    undo_last_pick
    wait_for_pick_count(draft, 0)
    assert_predicate draft.reload, :pick_timer_paused?

    visit draft_path(draft.public_id)
    players.each_with_index do |player, index|
      draft_player(player)
      wait_for_pick_count(draft, index + 1)
      wait_for_player_to_leave_board(player) unless index == players.size - 1
    end

    draft.reload
    picks = draft.picks.order(:overall_number)

    assert_predicate draft, :complete?
    assert_not_nil draft.completed_at
    assert_equal draft.total_picks, picks.size
    assert_equal (1..draft.total_picks).to_a, picks.pluck(:overall_number)
    assert_equal (1..draft.total_picks).map { |overall_number| draft.round_for_overall_number(overall_number) }, picks.pluck(:round)
    assert_equal players.map(&:id), picks.pluck(:player_id)
    assert_equal expected_teams.map(&:id), picks.pluck(:team_id)
  end

  private

  def rehearsal_draft
    league = leagues(:one)
    team_count = ENV.fetch("DRAFT_SIMULATION_TEAM_COUNT", 12).to_i
    rounds = ENV.fetch("DRAFT_SIMULATION_ROUNDS", 16).to_i
    first_team = teams(:one)
    teams = [ first_team ] + (2..team_count).map do |position|
      league.teams.create!(
        name: "Simulation Team #{position}",
        owner_name: "Manager #{position}",
        abbreviation: format("S%02d", position)
      )
    end
    draft = league.drafts.create!(
      name: "Browser Draft Rehearsal",
      team_count:,
      qb_slots: rounds,
      rb_slots: 0,
      wr_slots: 0,
      te_slots: 0,
      flex_slots: 0,
      k_slots: 0,
      dst_slots: 0,
      bench_slots: 0
    )
    teams.each_with_index { |team, index| draft.draft_entries.create!(team:, position: index + 1) }
    draft.start!

    players = draft.total_picks.times.map do |index|
      Player.create!(
        name: "Simulation Player #{index + 1}",
        position: "QB",
        pro_team: "ATL",
        ranking: index + 1
      )
    end

    expected_teams = (1..draft.total_picks).map { |overall_number| draft.team_for_overall_number(overall_number) }
    [ draft, players, expected_teams ]
  end

  def sign_in_as_commissioner
    visit new_session_path
    fill_in "Email", with: users(:commissioner).email
    click_button "Continue"
    assert_current_path verify_session_path
    users(:commissioner).issue_login_code!(code: "123456")
    fill_in "Sign-in code", with: "123456"
    click_button "Verify and sign in"
    assert_current_path root_path
  end

  def draft_player(player)
    find("[data-draft-player-id='#{player.id}']", match: :first).find_button("Draft", disabled: false).click
    find("button[aria-label='Confirm drafting #{player.name}']").click
  end

  def broadcast_message(draft, message)
    find("input[name='message']").set(message)
    click_button "Broadcast"
    assert_selector "#draft-#{draft.public_id}-pick-ticker:not([hidden])", text: message
  end

  def undo_last_pick
    accept_confirm { click_button "Undo last" }
  end

  def wait_for_pick_count(draft, count)
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop do
        return if draft.reload.picks.count == count

        sleep 0.05
      end
    end
  end

  def wait_for_player_to_leave_board(player)
    assert_no_selector "[data-draft-player-id='#{player.id}']"
  end
end
