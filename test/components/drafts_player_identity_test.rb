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
    end

    assert_match(/title="#{player.pro_team}"[^>]+size-7[^>]+bg-slate-400\/50/, desktop)
    assert_match(/class="[^"]*h-7[^"]*min-w-7[^"]*"[^>]*>#{player.position}</, desktop)
    assert_match(/title="#{player.pro_team}"[^>]+size-6[^>]+bg-slate-400\/50/, mobile)
    assert_match(/class="[^"]*h-6[^"]*min-w-6[^"]*"[^>]*>#{player.position}</, mobile)
  end
end
