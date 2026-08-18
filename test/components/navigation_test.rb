# frozen_string_literal: true

require "test_helper"

class Components::NavigationTest < ActiveSupport::TestCase
  test "renders signed-in commissioner navigation" do
    html = ApplicationController.renderer.render(Components::Navigation.new(current_user: users(:commissioner)))

    assert_includes html, "Draft home"
    assert_includes html, "League admin"
    assert_includes html, users(:commissioner).email
    assert_includes html, "Sign out"
  end

  test "renders the sign-in link for guests" do
    html = ApplicationController.renderer.render(Components::Navigation.new(current_user: nil))

    assert_includes html, "Sign in"
    assert_not_includes html, "League admin"
  end
end
