# frozen_string_literal: true

require "test_helper"

class Components::Drafts::PlayerIdentityTest < ActiveSupport::TestCase
  test "shares accessible identity markup across desktop and mobile variants" do
    player = players(:one)
    desktop = ApplicationController.renderer.render(Components::Drafts::PlayerIdentity.new(player:, variant: :desktop))
    mobile = ApplicationController.renderer.render(Components::Drafts::PlayerIdentity.new(player:, variant: :mobile))

    [ desktop, mobile ].each do |html|
      assert_includes html, player.name
      assert_includes html, player.position
      assert_includes html, player.pro_team
      assert_includes html, "sr-only"
      assert_includes html, "Questionable"
      assert_includes html, "ESPN injury status"
      assert_match(/aria-hidden(?:="true")?[^>]*>\+<\//, html)
      assert_match(/>Q<\//, html)
    end

    assert_match(/title="#{player.pro_team}"[^>]+size-7[^>]+bg-slate-400\/50/, desktop)
    assert_match(/class="[^"]*h-7[^"]*min-w-7[^"]*"[^>]*>#{player.position}</, desktop)
    assert_injury_badge_follows_team(desktop, player)
    assert_includes desktop, "break-words"
    refute_includes desktop, "truncate"
    assert_match(/title="#{player.pro_team}"[^>]+size-6[^>]+bg-slate-400\/50/, mobile)
    assert_match(/class="[^"]*h-6[^"]*min-w-6[^"]*"[^>]*>#{player.position}</, mobile)
    assert_injury_badge_follows_team(mobile, player)
    assert_includes mobile, "break-words"
    refute_includes mobile, "truncate"
  end

  test "renders the team logo as the portrait for defenses instead of a duplicate badge" do
    dst = Player.new(name: "New England Defense", position: "DST", pro_team: "NE")
    desktop = ApplicationController.renderer.render(Components::Drafts::PlayerIdentity.new(player: dst, variant: :desktop))
    mobile = ApplicationController.renderer.render(Components::Drafts::PlayerIdentity.new(player: dst, variant: :mobile))

    [ desktop, mobile ].each do |html|
      assert_equal 1, html.scan("teamlogos/nfl/500/ne.png").size
      refute_match(/font-black text-slate-500[^>]*>DST</, html)
    end
  end

  private

  def assert_injury_badge_follows_team(html, player)
    fragment = Nokogiri::HTML.fragment(html)
    team_name = fragment.css(".sr-only").find { |node| node.text == player.pro_team }
    injury_badge = fragment.at_css("[title^='ESPN injury status:']")

    assert_equal team_name.parent, injury_badge.parent
    assert_equal team_name.next_element, injury_badge
  end
end
