require "test_helper"

class DraftBoardTest < ActionDispatch::IntegrationTest
  test "completed picks retain their elapsed time on the board" do
    draft = drafts(:one)
    draft.update!(started_at: Time.zone.parse("2026-08-14 12:00:00"))
    pick = draft.picks.create!(
      team: teams(:one),
      player: players(:one),
      round: 1,
      overall_number: 1,
      created_at: Time.zone.parse("2026-08-14 12:01:01")
    )
    attach_headshot(players(:one))
    sign_in_as users(:member)

    get draft_path(draft.public_id, view: "board")

    assert_response :success
    assert_select "[data-draft-board-pick='true'] img[src*='/rails/active_storage/']", count: 2
    assert_select "#draft-#{draft.public_id}-board-cell-#{pick.overall_number}[title*='Pick time 1:01']", count: 1
    assert_select "#draft-#{draft.public_id}-board-cell-#{pick.overall_number}", count: 1 do |board_cells|
      assert_includes board_cells.first["class"], "bg-amber-400/20"
    end
    team_logo_url = ApplicationController.helpers.nfl_team_logo_url(players(:one).pro_team)
    assert_select "#draft-#{draft.public_id}-board-cell-#{pick.overall_number} img.size-7[src='#{team_logo_url}'][title='#{players(:one).pro_team}']", count: 1
    assert_select "#draft-#{draft.public_id}-board-cell-#{pick.overall_number} > span.absolute", text: "1.1", count: 1
    assert_select "#draft-#{draft.public_id}-board-cell-#{pick.overall_number} [data-mobile-draft-pick='#{pick.overall_number}']", text: /1\.1.*#{teams(:one).abbreviation}.*#{players(:one).name}.*#{players(:one).position}/m, count: 1 do |mobile_rows|
      assert_select mobile_rows.first, "img", count: 2
      assert_select mobile_rows.first, ".h-10.w-8 img[src*='/rails/active_storage/']", count: 1
      assert_select mobile_rows.first, "img.h-9.w-7[src='#{team_logo_url}']", count: 1
    end
    assert_select "#draft-#{draft.public_id}-board-cell-#{pick.overall_number}", text: /Rank/, count: 0
    assert_select "[data-pick-timer-elapsed-value]"
  end

  test "draft board uses the team logo for a defense pick" do
    draft = drafts(:one)
    defense = players(:two)
    defense.update!(name: "Buffalo Bills Defense", position: "DST", pro_team: "BUF", ranking: 100)
    pick = draft.picks.create!(team: teams(:one), player: defense, round: 1, overall_number: 1, elapsed_seconds: 42)
    draft.update!(status: :complete, completed_at: Time.current)
    sign_in_as users(:member)

    get draft_path(draft.public_id, view: "board")

    logo_url = ApplicationController.helpers.nfl_team_logo_url(defense.pro_team)
    assert_select "#draft-#{draft.public_id}-board-cell-#{pick.overall_number} [class~='bg-slate-400/50'] img[src='#{logo_url}'][title='BUF']", count: 2
    assert_select "#draft-#{draft.public_id}-board-cell-#{pick.overall_number} span", text: "Buffalo Bills", count: 1 do |names|
      refute_includes names.first["class"], "truncate"
      refute_includes names.first["class"], "hidden"
      assert_includes names.first["class"], "text-balance"
    end
    assert_select "#draft-#{draft.public_id}-board-cell-#{pick.overall_number} p", text: "Buffalo Bills", count: 1
    assert_select "#draft-#{draft.public_id}-board-cell-#{pick.overall_number}[title*='Pick time 0:42']", count: 1
    assert_select "#draft-#{draft.public_id}-board-cell-#{pick.overall_number} img[src='#{logo_url}']", count: 2
    assert_select "#draft-#{draft.public_id}-board-cell-#{pick.overall_number}", text: /DST - Rank 100/, count: 1
    assert_select "#draft-#{draft.public_id}-board-cell-#{pick.overall_number} [data-mobile-draft-pick='#{pick.overall_number}'] img", count: 1
    assert_select "#draft-#{draft.public_id}-board-cell-#{pick.overall_number} [data-mobile-draft-pick='#{pick.overall_number}'] .size-8 img", count: 1
  end

  private

  def attach_headshot(player)
    player.headshot.attach(io: file_fixture("headshot.png").open, filename: "headshot.png", content_type: "image/png")
    player.headshot.variant(:portrait).processed
  end
end
