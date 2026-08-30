require "application_system_test_case"

class UnsupportedBrowsersTest < ApplicationSystemTestCase
  test "update instructions work at desktop and phone sizes" do
    visit "/406-unsupported-browser.html"

    assert_title "Update your browser · Fantasy Draft"
    assert_selector "h1", text: "Your browser is out of date"
    assert_text "Software Update"
    assert_link "Get Chrome"
    assert_link "Get Firefox"
    assert_equal "rgb(2, 6, 23)", page.evaluate_script("getComputedStyle(document.documentElement).backgroundColor")
    capture_screenshot("unsupported-browser-desktop.png") if ENV["CAPTURE_SCREENSHOTS"]

    page.current_window.resize_to(390, 844)

    assert_selector ".message-card"
    assert_selector ".browser-links a", count: 2
    if ENV["CAPTURE_SCREENSHOTS"]
      page.current_window.resize_to(390, page.evaluate_script("document.documentElement.scrollHeight"))
      capture_screenshot("unsupported-browser-phone.png")
    end
  end

  private

  def capture_screenshot(filename)
    page.execute_script("document.querySelector('.message-card').style.animation = 'none'")
    save_screenshot Rails.root.join("tmp", filename)
  end
end
