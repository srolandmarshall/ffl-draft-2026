require "test_helper"

class EspnSeasonTest < ActiveSupport::TestCase
  test "summarizes imported draft positions and rounds" do
    season = espn_seasons(:one)
    season.draft_picks.create!(
      overall_number: 2,
      round: 2,
      round_pick: 1,
      espn_team_id: 7,
      team_name: "Red Hawks",
      team_abbreviation: "RED",
      espn_player_id: 42,
      player_name: "Amon-Ra St. Brown",
      position: "WR"
    )

    assert_equal 2, season.rounds
    assert_equal({ "MyString" => 1, "WR" => 1 }, season.position_counts)
  end
end
