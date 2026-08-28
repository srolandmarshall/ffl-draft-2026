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

  # The frame is what crops the portrait, so a caller that asks for one shape has to get the
  # same shape whether the headshot exists or the silhouette stands in for it. Before the
  # frame moved in here, every caller built its own box and the fallback branch quietly
  # dropped it.
  test "frames the headshot and the fallback identically" do
    framed = players(:one)
    framed.headshot.attach(io: StringIO.new("headshot"), filename: "headshot.png", content_type: "image/png")

    with_headshot = frame_of(framed, frame: "size-9 shrink-0 rounded-full")
    without_headshot = frame_of(players(:two), frame: "size-9 shrink-0 rounded-full")

    assert_equal with_headshot["class"], without_headshot["class"]
    assert_includes with_headshot["class"], "size-9 shrink-0 rounded-full"
    assert_includes with_headshot["class"], "overflow-hidden"
  end

  test "carries the frame's inline sizing on both branches" do
    sized = players(:one)
    sized.headshot.attach(io: StringIO.new("headshot"), filename: "headshot.png", content_type: "image/png")
    style = "height: 2.75rem; width: 2.25rem"

    assert_equal style, frame_of(sized, frame_style: style)["style"]
    assert_equal style, frame_of(players(:two), frame_style: style)["style"]
  end

  # Portraits keep their alpha channel, so the colour has to come from the box behind them.
  test "backs a defense with the logo plate and a skill player with slate" do
    defense = Player.new(name: "New England Defense", position: "DST", pro_team: "NE")

    assert_includes frame_of(defense)["class"], "bg-slate-400/50"
    assert_includes frame_of(players(:one))["class"], "bg-slate-800"
  end

  test "passes extra attributes through to the image" do
    player = players(:one)
    player.headshot.attach(io: StringIO.new("headshot"), filename: "headshot.png", content_type: "image/png")

    html = ApplicationController.renderer.render(
      Components::PlayerPortrait.new(player:, data: { roster_player_image: true })
    )

    assert_includes html, "data-roster-player-image"
  end

  private

  def frame_of(player, **options)
    html = ApplicationController.renderer.render(Components::PlayerPortrait.new(player:, **options), layout: false)
    Nokogiri::HTML5.fragment(html).at_css("div")
  end
end
