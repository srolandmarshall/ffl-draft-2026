# frozen_string_literal: true

require "test_helper"

class Components::Drafts::BoardCellTest < ActiveSupport::TestCase
  test "renders a completed pick's responsive identity and elapsed time" do
    draft = drafts(:one)
    player = players(:one)
    player.headshot.attach(io: StringIO.new("headshot"), filename: "headshot.png", content_type: "image/png")
    pick = draft.picks.create!(team: teams(:one), player:, round: 1, overall_number: 1)

    cell = board_cell(draft:, pick:, elapsed_seconds: 61)
    team_logo_url = ApplicationController.helpers.nfl_team_logo_url(player.pro_team)

    assert_equal "true", cell["data-draft-board-pick"]
    assert_includes cell["title"], "Pick time 1:01"
    assert_includes cell["class"], "bg-amber-400/20"
    assert_equal "1.1", cell.at_css("> span.absolute").text
    assert_equal 2, cell.css("img[src*='/rails/active_storage/']").size
    assert_equal 1, cell.css("img.size-7[src='#{team_logo_url}'][title='#{player.pro_team}']").size

    mobile_pick = cell.at_css("[data-mobile-draft-pick='#{pick.overall_number}']")
    assert_includes mobile_pick.text, "1.1"
    assert_includes mobile_pick.text, teams(:one).abbreviation
    assert_includes mobile_pick.text, player.name
    assert_includes mobile_pick.text, player.position
    assert_equal 2, mobile_pick.css("img").size
    assert_equal 1, mobile_pick.css(".h-10.w-8 img[src*='/rails/active_storage/']").size
    assert_equal 1, mobile_pick.css("img.h-9.w-7[src='#{team_logo_url}']").size
    refute_match(/Rank/, cell.text)
  end

  test "uses only the team logo as a defense portrait" do
    draft = drafts(:one)
    defense = players(:two)
    defense.update!(name: "Buffalo Bills Defense", position: "DST", pro_team: "BUF", ranking: 100)
    pick = draft.picks.create!(team: teams(:one), player: defense, round: 1, overall_number: 1)
    draft.update!(status: :complete, completed_at: Time.current)

    cell = board_cell(draft:, pick:, elapsed_seconds: 42)
    logo_url = ApplicationController.helpers.nfl_team_logo_url(defense.pro_team)
    desktop_name = cell.at_css("span.text-balance")
    mobile_pick = cell.at_css("[data-mobile-draft-pick='#{pick.overall_number}']")

    assert_equal 2, cell.css("[class~='bg-slate-400/50'] img[src='#{logo_url}'][title='BUF']").size
    assert_equal "Buffalo Bills", desktop_name.text
    refute_includes desktop_name["class"], "truncate"
    refute_includes desktop_name["class"], "hidden"
    assert_equal "Buffalo Bills", cell.at_css("p").text
    assert_includes cell["title"], "Pick time 0:42"
    assert_includes cell.text, "DST - Rank 100"
    assert_equal 1, mobile_pick.css("img").size
    assert_equal 1, mobile_pick.css(".size-8 img").size
  end

  private

  def board_cell(draft:, pick:, elapsed_seconds:)
    html = ApplicationController.renderer.render(
      Components::Drafts::BoardCell.new(
        draft:,
        team: pick.team,
        overall_number: pick.overall_number,
        pick:,
        elapsed_seconds:
      )
    )

    Nokogiri::HTML5.fragment(html).at_css("[data-draft-board-pick]")
  end
end
