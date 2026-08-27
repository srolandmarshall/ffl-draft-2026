require "application_system_test_case"

class DraftSchedulingsTest < ApplicationSystemTestCase
  test "selecting a scheduled start in the date picker creates a scheduled draft" do
    league = leagues(:one)
    scheduled_date = Date.current + 1.day
    sign_in_in_browser(users(:commissioner))

    visit new_admin_league_draft_path(league)
    fill_in "Name", with: "Browser Scheduled Draft"
    select "2 teams", from: "Number of teams"
    email_fields = all("textarea[name*='[emails]']", visible: :all)
    email_fields.first.set("riley@example.com")
    email_fields[1].set("browser-opponent@example.com")

    find_field("Scheduled start (Eastern Time)").click
    within ".air-datepicker" do
      find(".air-datepicker-cell.-day-:not(.-other-month-)", text: scheduled_date.day.to_s, match: :first).click
    end
    assert_field "Scheduled start (Eastern Time)", with: /\A#{scheduled_date.strftime("%Y-%m-%d")}/

    click_button "Create Draft"

    assert_text "Draft created with"
    draft = league.drafts.find_by!(name: "Browser Scheduled Draft")
    assert_equal scheduled_date, draft.scheduled_start_at.to_date
  end
end
