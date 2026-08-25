# frozen_string_literal: true

require "test_helper"

class DraftsStatComponentsTest < ActiveSupport::TestCase
  test "renders touchdown and production groups in both layouts" do
    touchdowns = [ [ "REC", 8 ] ]
    groups = [ { label: "Receiving", stats: [ [ "YDS", "1,200" ], [ "YPG", "75.0" ] ] } ]

    desktop = ApplicationController.renderer.render(Components::Drafts::Touchdowns.new(stats: touchdowns))
    mobile = ApplicationController.renderer.render(Components::Drafts::ProductionGroups.new(groups:, variant: :mobile))

    assert_includes desktop, "REC"
    assert_includes mobile, "Receiving"
    assert_includes mobile, "1,200"
  end
end
