require "test_helper"

class AuthenticationAndSetupTest < ActionDispatch::IntegrationTest
  def with_env(name)
    original = Rails.env
    Rails.env = ActiveSupport::EnvironmentInquirer.new(name)
    yield
  ensure
    Rails.env = original
  end

  test "anonymous visitors are asked for an email" do
    get root_path

    assert_redirected_to new_session_path
  end

  test "outdated browsers receive update instructions and browser alternatives" do
    safari_16 = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " \
      "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6.1 Safari/605.1.15"

    get root_path, headers: { "User-Agent" => safari_16 }

    assert_response :not_acceptable
    assert_select "h1", "Your browser is out of date"
    assert_select "link[rel='stylesheet'][href='/406-unsupported-browser.css']"
    assert_select "a[href='https://www.google.com/chrome/']", "Get Chrome"
    assert_select "a[href='https://www.mozilla.org/firefox/new/']", "Get Firefox"
    assert_includes response.body, "Software Update"
  end

  test "an unassigned email cannot request a sign-in code" do
    assert_no_difference("User.count") do
      post session_path, params: { email: "unassigned@example.com" }
    end

    assert_redirected_to new_session_path
    assert_equal "That email is not assigned to a team.", flash[:alert]
  end

  test "an assigned email receives a code and can sign in with it" do
    assert_enqueued_emails 1 do
      post session_path, params: { email: users(:member).email }
    end

    assert_redirected_to verify_session_path
    code = users(:member).issue_login_code!(code: "123456")
    post verify_session_path, params: { code: }

    assert_redirected_to root_path
    assert_equal "Logged in as \"#{teams(:one).name}\".", flash[:notice]
  end

  test "a sign-in code is sent to the associated email that was submitted" do
    user = users(:member)
    submitted_email = "riley.secondary@example.com"
    user.user_emails.create!(email: submitted_email)

    assert_emails 1 do
      perform_enqueued_jobs do
        post session_path, params: { email: submitted_email }
      end
    end

    assert_equal [ submitted_email ], ActionMailer::Base.deliveries.last.to

    user.update!(login_code_sent_at: 1.minute.ago)
    assert_emails 1 do
      perform_enqueued_jobs do
        post resend_login_code_session_path
      end
    end

    assert_equal [ submitted_email ], ActionMailer::Base.deliveries.last.to
  end

  test "a user can resend a sign-in code after the one-minute wait" do
    user = users(:member)
    post session_path, params: { email: user.email }

    get verify_session_path
    assert_select "input[data-login-code-resend-target='submit'][disabled]", count: 1
    assert_select "input[data-login-code-resend-target='submit'][value='Resend code (1:00)']", count: 1

    assert_no_enqueued_emails do
      post resend_login_code_session_path
    end
    assert_equal "Please wait a minute before requesting another code.", flash[:alert]

    user.update!(login_code_sent_at: 1.minute.ago)
    assert_enqueued_emails 1 do
      post resend_login_code_session_path
    end

    assert_redirected_to verify_session_path
    assert_equal "We sent you a new sign-in code.", flash[:notice]
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

  test "start and restart draft buttons break out of the drafts turbo frame" do
    sign_in_as users(:commissioner)
    live_draft = drafts(:one)
    setup_draft = live_draft.league.drafts.create!(name: "Setup Draft", public_id: "setup-draft", status: :setup, rounds: 2)

    get admin_league_path(live_draft.league)

    assert_response :success
    assert_select "form[action='#{start_admin_league_draft_path(live_draft.league, setup_draft)}'][data-turbo-frame='_top']"
    assert_select "form[action='#{restart_admin_league_draft_path(live_draft.league, live_draft)}'][data-turbo-frame='_top']"
  end

  test "auto-draft button appears for a live draft but not a completed one" do
    sign_in_as users(:commissioner)
    live_draft = drafts(:one)
    completed_draft = live_draft.league.drafts.create!(name: "Done Draft", public_id: "done-draft", status: :complete, rounds: 1, completed_at: Time.current)

    get admin_league_path(live_draft.league)

    assert_response :success
    assert_select "form[action='#{auto_draft_admin_league_draft_path(live_draft.league, live_draft)}'][data-controller='triple-confirm'][data-turbo-frame='_top']"
    assert_select "form[action='#{auto_draft_admin_league_draft_path(live_draft.league, completed_draft)}']", count: 0
  end

  test "auto-draft fills every remaining pick and redirects into the completed draft" do
    sign_in_as users(:commissioner)
    league = leagues(:one)
    team_a = teams(:one)
    team_b = league.teams.create!(name: "Team B", owner_name: "Bailey", abbreviation: "TMB")
    draft = league.drafts.create!(
      name: "Auto Draft Integration", public_id: "auto-draft-integration", status: :setup, rounds: 1,
      qb_slots: 1, rb_slots: 0, wr_slots: 0, te_slots: 0, flex_slots: 0, k_slots: 0, dst_slots: 0, bench_slots: 0
    )
    draft.draft_entries.create!(team: team_a, position: 1)
    draft.draft_entries.create!(team: team_b, position: 2)
    Player.create!(name: "Auto QB One", position: "QB", pro_team: "FA", active: true, ranking: 1)
    Player.create!(name: "Auto QB Two", position: "QB", pro_team: "FA", active: true, ranking: 2)

    patch auto_draft_admin_league_draft_path(league, draft)

    assert_redirected_to draft_path(draft.public_id)
    assert draft.reload.complete?
    assert_equal 2, draft.picks.count
  end

  test "a regular member cannot trigger auto-draft" do
    sign_in_as users(:member)
    draft = drafts(:one)

    assert_no_difference("Pick.count") do
      patch auto_draft_admin_league_draft_path(draft.league, draft)
    end

    assert_redirected_to root_path
  end

  test "auto-draft is unavailable in production" do
    sign_in_as users(:commissioner)
    draft = drafts(:one)

    with_env("production") do
      patch auto_draft_admin_league_draft_path(draft.league, draft)
    end

    assert_response :not_found
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

  test "a scheduled draft exposes a draggable saved draft order" do
    sign_in_as users(:commissioner)
    league = leagues(:one)
    draft = league.drafts.create!(
      name: "Scheduled draft",
      team_count: 2,
      qb_slots: 1,
      rb_slots: 2,
      wr_slots: 2,
      te_slots: 1,
      flex_slots: 1,
      k_slots: 0,
      dst_slots: 1,
      bench_slots: 5,
      scheduled_start_at: 1.day.from_now
    )
    second_team = league.teams.create!(name: "Second Team", owner_name: "Second Owner", abbreviation: "SEC")
    draft.draft_entries.create!(team: teams(:one), position: 1)
    draft.draft_entries.create!(team: second_team, position: 2)

    get admin_league_path(league)
    assert_select "a", text: "Edit draft & order"

    get edit_admin_league_draft_path(league, draft)
    assert_response :success
    assert_select "[data-controller='draft-order']", count: 1
    assert_select "fieldset[draggable='true'][data-draft-order-target='item']", count: 20
    assert_select "legend[data-draft-order-target='position']", text: "Pick 1"
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
    code = user.issue_login_code!(code: "123456")
    post verify_session_path, params: { code: }
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
