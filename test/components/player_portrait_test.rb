# frozen_string_literal: true

require "test_helper"

class Components::PlayerPortraitTest < ActiveSupport::TestCase
  test "renders a headshot when one is available" do
    player = players(:one)
    player.headshot.attach(io: file_fixture("headshot.png").open, filename: "headshot.png", content_type: "image/png")
    player.headshot.variant(:portrait).processed

    html = ApplicationController.renderer.render(Components::PlayerPortrait.new(player:))

    assert_includes html, "/rails/active_storage/representations/proxy/"
    assert_includes html, "h-full w-full"
  end

  test "renders the shared fallback when a headshot is unavailable" do
    html = ApplicationController.renderer.render(Components::PlayerPortrait.new(player: players(:one)))

    assert_includes html, "text-slate-600"
  end

  test "uses the NFL logo as a defense portrait" do
    player = Player.new(name: "New England Defense", position: "DST", pro_team: "NE")

    html = ApplicationController.renderer.render(Components::PlayerPortrait.new(player:))

    assert_includes html, "teamlogos/nfl/500/ne.png"
  end
end
