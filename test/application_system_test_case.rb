require "test_helper"
require "capybara/cuprite"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite,
    screen_size: [ 1400, 1400 ],
    options: {
      js_errors: true,
      browser_path: ENV["CUPRITE_BROWSER_PATH"].presence,
      browser_options: ({ "no-sandbox": nil, "disable-dev-shm-usage": nil } if ENV["CUPRITE_NO_SANDBOX"] == "1")
    }.compact

  private

  def sign_in_in_browser(user)
    visit new_session_path
    fill_in "Email", with: user.email
    click_button "Continue"

    code = user.reload.issue_login_code!(code: "123456")
    fill_in "Sign-in code", with: code
    click_button "Verify and sign in"
  end
end
