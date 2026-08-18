require "test_helper"

class LeaguePlayerScoreTest < ActiveSupport::TestCase
  test "replaces a league season with scores for known ESPN players" do
    league = leagues(:one)

    scores = [
      DataSources::Espn::Client::PlayerScore.new(espn_id: 1, points: 345.6, stats: { "99" => 42 }),
      DataSources::Espn::Client::PlayerScore.new(espn_id: 999_999, points: 200, stats: {})
    ]
    imported = LeaguePlayerScore.replace_for!(league:, season: 2025, scores:)

    assert_equal 1, imported
    assert_equal 1, LeaguePlayerScore.where(league:, season: 2025).count
    assert_equal 345.6, LeaguePlayerScore.find_by!(league:, season: 2025).points
    assert_equal 42, LeaguePlayerScore.find_by!(league:, season: 2025).stats.fetch("99")
  end
  test "presents defensive production and omits zero touchdowns" do
    score = league_player_scores(:one)
    score.player.update!(position: "DST")
    score.update!(stats: { "99" => 68, "95" => 10, "96" => 4, "97" => 2, "94" => 1, "101" => 0, "102" => 1 })

    assert_equal [ [ "SACK", 68 ], [ "INT", 10 ], [ "FR", 4 ], [ "BLK", 2 ] ], score.dst_stat_groups.first[:stats]
    assert_equal [ [ "DEF", 1 ], [ "PR", 1 ] ], score.dst_touchdown_stats
  end
end
