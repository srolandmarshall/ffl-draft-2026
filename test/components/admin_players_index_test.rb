# frozen_string_literal: true

require "test_helper"

class Components::Admin::Players::IndexTest < ActiveSupport::TestCase
  test "shows a portrait or a silhouette placeholder for each player" do
    player_with_headshot = players(:one)
    player_with_headshot.headshot.attach(io: StringIO.new("headshot"), filename: "headshot.png", content_type: "image/png")
    player_without_headshot = players(:two)

    html = ApplicationController.renderer.render(
      Components::Admin::Players::Index.new(players: [ player_with_headshot, player_without_headshot ], player_count: 2)
    )

    assert_includes html, player_with_headshot.name
    assert_includes html, player_without_headshot.name
    document = Nokogiri::HTML5.fragment(html)
    rows = document.css("tbody tr")

    assert_equal 1, rows.first.css("img[src*='/rails/active_storage/representations/proxy/']").size
    assert_empty rows.first.css("svg")
    assert_equal 1, rows.last.css("svg[aria-hidden='true']").size
    assert_empty rows.last.css("img")
  end
end
