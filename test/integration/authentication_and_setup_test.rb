require "test_helper"

class AuthenticationAndSetupTest < ActionDispatch::IntegrationTest
  test "anonymous visitors are asked for an email" do
    get root_path

    assert_redirected_to new_session_path
  end

  test "a regular member cannot open commissioner tools" do
    sign_in_as users(:member)

    get admin_root_path

    assert_redirected_to root_path
    assert_equal "Commissioner access is required.", flash[:alert]
  end

  test "a commissioner can promote another user" do
    sign_in_as users(:commissioner)

    patch admin_user_path(users(:member)), params: { user: { role: "commissioner" } }

    assert_redirected_to admin_users_path
    assert users(:member).reload.commissioner?
  end

  test "a commissioner cannot demote their own account" do
    commissioner = users(:commissioner)
    sign_in_as commissioner

    patch admin_user_path(commissioner), params: { user: { role: "member" } }

    assert_redirected_to admin_users_path
    assert commissioner.reload.commissioner?
  end

  test "a commissioner can delete a league and its draft data" do
    sign_in_as users(:commissioner)
    league = leagues(:one)
    draft = drafts(:one)
    team = teams(:one)

    delete admin_league_path(league)

    assert_redirected_to admin_leagues_path
    assert_not League.exists?(league.id)
    assert_not Draft.exists?(draft.id)
    assert_not Team.exists?(team.id)
  end

  test "league delete control only appears on the edit page" do
    sign_in_as users(:commissioner)
    league = leagues(:one)

    get admin_league_path(league)
    assert_response :success
    assert_select "button", text: "Delete league", count: 0
    assert_select "a[data-turbo-frame='_top']", text: "+ Create draft", count: 1

    get edit_admin_league_path(league)
    assert_response :success
    assert_select "button", text: "Delete league", count: 1
  end

  test "a completed draft links to its draft-board result from the league page" do
    sign_in_as users(:commissioner)
    draft = drafts(:one)
    draft.update!(status: :complete, completed_at: Time.current)

    get admin_league_path(draft.league)

    assert_response :success
    assert_select "a[href='#{draft_path(draft.public_id, view: "board")}'][data-turbo-frame='_top']", text: "View draft result →", count: 1
    assert_select "a", text: "Open room →", count: 0
  end

  test "league team order seeds the next draft without changing an existing draft" do
    sign_in_as users(:commissioner)
    follow_redirect!
    league = leagues(:one)
    existing_team = teams(:one)
    next_team = league.teams.create!(name: "Next Team", owner_name: "Next Owner", abbreviation: "NXT")
    existing_draft_team_ids = drafts(:one).draft_entries.pluck(:team_id)

    patch team_order_admin_league_path(league), params: { team_ids: [ next_team.id, existing_team.id ] }

    assert_redirected_to admin_league_path(league)
    assert_nil flash[:notice]
    assert_equal [ next_team, existing_team ], league.teams.in_draft_order.to_a
    assert_equal existing_draft_team_ids, drafts(:one).draft_entries.reload.pluck(:team_id)

    get new_admin_league_draft_path(league)
    assert_response :success
    assert_select "input[name='draft[team_slots][0][id]'][value='#{next_team.id}']"
    assert_select "input[name='draft[team_slots][1][id]'][value='#{existing_team.id}']"
  end

  test "archived teams are left out of a new draft's defaults" do
    sign_in_as users(:commissioner)
    league = leagues(:one)
    archived_team = league.teams.create!(name: "Benched", owner_name: "Gone", abbreviation: "BEN", archived: true)

    get new_admin_league_draft_path(league)

    assert_response :success
    assert_select "input[name='draft[team_slots][0][id]'][value='#{archived_team.id}']", count: 0
  end

  test "league settings seed the next draft without changing an existing draft" do
    sign_in_as users(:commissioner)
    league = leagues(:one)
    existing_draft = drafts(:one)
    existing_ppr = existing_draft.ppr

    patch admin_league_path(league), params: {
      league: {
        name: league.name,
        season: league.season,
        ppr: 0.5,
        draft_type: "linear",
        qb_slots: 1,
        rb_slots: 2,
        wr_slots: 3,
        te_slots: 1,
        flex_slots: 2,
        k_slots: 0,
        dst_slots: 1,
        bench_slots: 5
      }
    }

    assert_redirected_to admin_league_path(league)
    assert_equal 0.5, league.reload.ppr
    assert_equal 15, league.roster_size
    assert_equal existing_ppr, existing_draft.reload.ppr

    get new_admin_league_draft_path(league)
    assert_response :success
    assert_select "select[name='draft[ppr]'] option[selected][value='0.5']"
    assert_select "select[name='draft[draft_type]'] option[selected][value='linear']"
    assert_select "input[name='draft[wr_slots]'][value='3']"
    assert_select "label", text: "Scheduled start (Eastern Time)"
    assert_select "[data-controller='date-picker'][data-date-picker-timepicker-value='true']", count: 1
    assert_select "input#draft_scheduled_start_at[name='draft[scheduled_start_at]'][data-date-picker-target='input']", count: 1
    assert_select "input[type='datetime-local']", count: 0
  end

  test "a regular member cannot delete a league" do
    sign_in_as users(:member)
    league = leagues(:one)

    assert_no_difference("League.count") do
      delete admin_league_path(league)
    end

    assert_redirected_to root_path
    assert League.exists?(league.id)
  end

  test "an assigned email opens its draft but not another draft" do
    sign_in_as users(:member)

    get draft_path(drafts(:one).public_id)
    assert_response :success

    get draft_path(drafts(:two).public_id)
    assert_redirected_to root_path
  end

  test "a secondary email signs into the same assigned account" do
    user = users(:member)
    user.user_emails.create!(email: "riley.secondary@example.com")

    post session_path, params: { email: "riley.secondary@example.com" }
    get draft_path(drafts(:one).public_id)

    assert_response :success
    assert_select "p", text: /You're up now/
  end

  test "commissioner creates configured draft and assigns team emails" do
    sign_in_as users(:commissioner)
    league = League.create!(name: "New League", season: 2027, roster_size: 16)
    alex = User.create!(email: "alex@example.com")
    alex.user_emails.create!(email: "coowner@example.com")

    assert_difference("Draft.count", 1) do
      assert_difference("Team.count", 2) do
        post admin_league_drafts_path(league), params: {
          draft: {
            name: "2027 Draft",
            scheduled_start_at: "2027-08-25 20:00",
            team_count: 2,
            draft_type: "snake",
            ppr: 0.5,
            qb_slots: 1,
            rb_slots: 2,
            wr_slots: 2,
            te_slots: 1,
            flex_slots: 1,
            k_slots: 0,
            dst_slots: 1,
            bench_slots: 5,
            team_slots: {
              "0" => { name: "Alpha", owner_name: "Alex", abbreviation: "ALP", emails: "alex@example.com, coowner@example.com" },
              "1" => { name: "Beta", owner_name: "Bailey", abbreviation: "BET", emails: "bailey@example.com" }
            }
          }
        }
      end
    end

    draft = league.drafts.last
    assert_redirected_to admin_league_path(league)
    assert_equal 2, draft.team_count
    assert_equal 13, draft.rounds
    assert_equal 0.5, draft.ppr
    assert_equal Time.zone.parse("2027-08-25 20:00"), draft.scheduled_start_at
    assert_equal %w[alex@example.com coowner@example.com], draft.teams.first.emails
    assert_equal [ alex ], draft.teams.first.users
  end
end
