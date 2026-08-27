require "test_helper"

class DraftPlayerListTest < ActionDispatch::IntegrationTest
  test "caps the default window and returns a deep text match" do
    40.times do |index|
      Player.create!(
        name: format("Depth Player %02d", index + 1),
        position: "WR",
        pro_team: "ATL",
        ranking: index + 1
      )
    end
    deep_player = Player.create!(name: "Deep Search Sleeper", position: "TE", pro_team: "SEA", ranking: 999)
    draft = drafts(:one)
    sign_in_as users(:member)

    get players_draft_path(draft.public_id)

    assert_response :success
    rendered_player_ids = css_select("[data-draft-player-id]").map { |element| element["data-draft-player-id"] }.uniq
    assert_equal 36, rendered_player_ids.size
    refute_includes rendered_player_ids, deep_player.id.to_s

    get players_draft_path(draft.public_id), params: { query: "search sleeper" }

    assert_response :success
    assert_select "turbo-frame#draft-sunday-draft-players"
    assert_select "[data-draft-player-id='#{deep_player.id}']"
  end

  test "backfills the player window after a player is drafted" do
    40.times do |index|
      Player.create!(name: "Available Player #{index + 1}", position: "WR", pro_team: "ATL", ranking: index + 1)
    end
    draft = drafts(:one)
    drafted_player = Player.by_ranking.first
    draft.picks.create!(team: teams(:one), player: drafted_player, round: 1, overall_number: 1)
    sign_in_as users(:member)

    get players_draft_path(draft.public_id)

    assert_response :success
    rendered_player_ids = css_select("[data-draft-player-id]").map { |element| element["data-draft-player-id"] }.uniq
    assert_equal 36, rendered_player_ids.size
    refute_includes rendered_player_ids, drafted_player.id.to_s
  end

  test "filters beyond the default player window by position and team" do
    36.times do |index|
      Player.create!(name: "Window Player #{index + 1}", position: "RB", pro_team: "BUF", ranking: index + 1)
    end
    deep_player = Player.create!(name: "Deep Filter Sleeper", position: "TE", pro_team: "SEA", ranking: 999)
    sign_in_as users(:member)

    get players_draft_path(drafts(:one).public_id), params: { positions: [ "TE" ], teams: [ "SEA" ] }

    assert_response :success
    assert_select "[data-draft-player-id='#{deep_player.id}']"
    assert_select "turbo-frame[data-player-refresh-url*='positions%5B%5D=TE'][data-player-refresh-url*='teams%5B%5D=SEA']"
  end
end
