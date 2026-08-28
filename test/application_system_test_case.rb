require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Capybara's Puma server needs to read the same draft and login-code changes.
  self.use_transactional_tests = false

  remote_selenium_url = ENV["SELENIUM_REMOTE_URL"]

  if remote_selenium_url.present?
    Capybara.server_host = ENV.fetch("CAPYBARA_SERVER_HOST")
    driven_by :selenium,
      using: :headless_chrome,
      screen_size: [ 1400, 1400 ],
      options: { browser: :remote, url: remote_selenium_url }
  else
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
  end
end
