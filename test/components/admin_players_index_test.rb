# frozen_string_literal: true

require "test_helper"

class Components::Admin::Players::IndexTest < ActiveSupport::TestCase
  test "shows a portrait or a position placeholder for each player" do
    player_with_headshot = players(:one)
    player_with_headshot.headshot.attach(io: StringIO.new("headshot"), filename: "headshot.png", content_type: "image/png")
    player_without_headshot = players(:two)

    html = ApplicationController.renderer.render(
      Components::Admin::Players::Index.new(players: [ player_with_headshot, player_without_headshot ], player_count: 2)
    )

    assert_includes html, player_with_headshot.name
    assert_match(/src="\/rails\/active_storage\/representations\/proxy\//, html)
    assert_match(/font-black text-slate-500[^>]*>#{player_without_headshot.position}</, html)
  end
end
