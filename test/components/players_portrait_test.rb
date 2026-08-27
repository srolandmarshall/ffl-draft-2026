# frozen_string_literal: true

require "test_helper"

class Components::Players::PortraitTest < ActiveSupport::TestCase
  test "renders an attached player portrait inside the supplied presentation frame" do
    player = players(:one)
    player.headshot.attach(io: StringIO.new("headshot"), filename: "headshot.png", content_type: "image/png")

    html = render_portrait(player)

    assert_includes portrait_html(html), "size-10"
    assert_includes portrait_html(html), "bg-slate-800"
    assert_includes portrait_html(html), "object-cover"
    assert_match(%r{/rails/active_storage/representations/proxy/}, portrait_html(html))
    refute_includes portrait_html(html), "svg"
  end

  test "renders a silhouette when no portrait is available" do
    html = render_portrait(players(:one))

    assert_includes portrait_html(html), "size-10"
    assert_includes portrait_html(html), "bg-slate-800"
    assert_includes portrait_html(html), "svg"
    assert_includes portrait_html(html), "text-slate-600"
  end

  test "uses the team logo for a defense portrait" do
    defense = Player.new(name: "New England Defense", position: "DST", pro_team: "NE")

    html = render_portrait(defense)

    assert_includes portrait_html(html), "bg-slate-400/50"
    assert_includes portrait_html(html), "teamlogos/nfl/500/ne.png"
    assert_includes portrait_html(html), "title=\"NE\""
  end

  private

  def render_portrait(player)
    ApplicationController.renderer.render(
      Components::Players::Portrait.new(
        player:,
        classes: "size-10 rounded-full border border-white/10",
        data: { players_portrait: true }
      )
    )
  end

  def portrait_html(html)
    Nokogiri::HTML5.fragment(html).at_css("[data-players-portrait]").to_html
  end
end
