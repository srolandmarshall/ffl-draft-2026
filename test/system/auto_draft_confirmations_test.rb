require "application_system_test_case"

class AutoDraftConfirmationsTest < ApplicationSystemTestCase
  test "accepting all three confirmations auto-drafts the remaining picks" do
    league = leagues(:one)
    team_a = teams(:one)
    team_b = league.teams.create!(name: "Browser Team B", owner_name: "Bailey", abbreviation: "BTB")
    draft = league.drafts.create!(
      name: "Browser Auto Draft", public_id: "browser-auto-draft", status: :setup, team_count: 2, rounds: 1,
      qb_slots: 1, rb_slots: 0, wr_slots: 0, te_slots: 0, flex_slots: 0, k_slots: 0, dst_slots: 0, bench_slots: 0
    )
    draft.draft_entries.create!(team: team_a, position: 1)
    draft.draft_entries.create!(team: team_b, position: 2)
    Player.create!(name: "Browser Auto QB One", position: "QB", pro_team: "FA", active: true, ranking: 1)
    Player.create!(name: "Browser Auto QB Two", position: "QB", pro_team: "FA", active: true, ranking: 2)
    sign_in_in_browser(users(:commissioner))

    visit admin_league_path(league)

    accept_confirm(/Final check/) do
      accept_confirm(/This cannot be undone/) do
        accept_confirm(/Auto-draft the rest/) do
          click_button "Auto-draft rest", match: :first
        end
      end
    end

    assert_equal 2, draft.reload.picks.count
    assert_predicate draft, :complete?
    assert_text "Auto-drafted the remaining picks for Browser Auto Draft"
  end
end
