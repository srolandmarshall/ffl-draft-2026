# frozen_string_literal: true

require "test_helper"

class Components::Drafts::ActionTest < ActiveSupport::TestCase
  test "renders a disabled action for viewers who cannot pick" do
    html = ApplicationController.renderer.render(
      Components::Drafts::Action.new(draft: drafts(:one), player: players(:one), can_make_pick: false)
    )

    assert_includes html, "data-controller=\"draft-pick\""
    assert_includes html, "disabled"
    assert_includes html, "Confirm drafting #{players(:one).name}"
  end
end
