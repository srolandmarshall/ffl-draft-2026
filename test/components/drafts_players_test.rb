# frozen_string_literal: true

require "test_helper"

class Components::Drafts::PlayersTest < ActiveSupport::TestCase
  # Both breakpoints render the same player from the same stats. These lock the numbers that
  # appear in each so a layout change to one cannot quietly disagree with the other.
  # The presenter formats points with ActiveSupport::NumberHelper rather than the view's
  # number_with_precision; this pins the two to the same output.
  test "shows the same fantasy points in the desktop row and the mobile card" do
    player = players(:one)
    document = render_list(player)

    formatted = ApplicationController.helpers.number_with_precision(
      league_player_scores(:one).points, precision: 1
    )
    assert_equal "333.3", formatted
    assert_equal formatted, desktop_cell(document, player, 3).text.strip
    assert_equal formatted, mobile_metric(document, player, "FP").text.strip
  end

  test "falls back to a dash for a player with no score in this league" do
    player = players(:two)
    document = render_list(player)

    assert_equal "—", desktop_cell(document, player, 3).text.strip
    assert_equal "—", mobile_metric(document, player, "FP").text.strip
  end

  test "renders every player once per breakpoint" do
    document = render_list(players(:one), players(:two))

    assert_equal 2, document.css("tbody tr[data-draft-player-id]").size
    assert_equal 2, document.css("[data-mobile-player-row]").size
    assert_equal 4, document.css("[data-draft-player-id]").size
  end

  test "shows the empty state in both layouts when nothing matches" do
    document = render_list

    assert_equal 1, document.css("tbody td[colspan='7']").size

    leaves = document.css("td, div").select do |node|
      node.element_children.empty? && node.text.strip == Components::Drafts::Players::EMPTY_MESSAGE
    end
    assert_equal 2, leaves.size, "expected the empty state in both the table and the mobile list"
  end

  test "keeps the pick action disabled when the viewer cannot pick" do
    document = render_list(players(:one), can_make_pick: false)

    triggers = document.css("button[data-draft-pick-target='trigger']")
    assert_equal 2, triggers.size
    triggers.each { |trigger| assert trigger.attribute("disabled") }
  end

  private

  def render_list(*players, can_make_pick: true)
    room = DraftRoom.new(
      draft: drafts(:one),
      selected_team: teams(:one),
      picks: [],
      pick_elapsed_seconds: {},
      current_pick_elapsed_seconds: 0,
      available_players: players,
      available_teams: players.map(&:pro_team).uniq,
      player_filters: { query: "", positions: [], teams: [] }
    )
    html = ApplicationController.renderer.render(
      Components::Drafts::Players.new(room:, can_make_pick:), layout: false
    )
    Nokogiri::HTML5.fragment(html)
  end

  def desktop_cell(document, player, index)
    document.at_css("tbody tr[data-draft-player-id='#{player.id}']").css("td")[index - 1]
  end

  def mobile_metric(document, player, label)
    card = document.at_css("[data-mobile-player-row][data-draft-player-id='#{player.id}']")
    card.css("dt").find { |dt| dt.text.include?(label) }.next_element
  end
end
