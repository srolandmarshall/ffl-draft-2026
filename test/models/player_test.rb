require "test_helper"

class PlayerTest < ActiveSupport::TestCase
  test "formats position stats and applies the draft's PPR setting" do
    player = players(:one)

    assert_equal "360/550 · 4,200 pass yd · 31 TD · 9 INT · 302 rush yd", player.actual_stat_line
    assert_equal "360/550 · 4,200 yd · 31 TD · 9 INT", player.passing_stat_line
    assert_equal "61 att · 302 yd · 4 TD", player.rushing_stat_line
    assert_equal [ [ "Pass", player.passing_stat_line ], [ "Rush", player.rushing_stat_line ] ], player.draft_stat_lines
    assert_equal [ "Passing", "Rushing" ], player.draft_stat_groups.map { |group| group[:label] }
    assert_equal [ [ "CMP", 360 ], [ "ATT", 550 ], [ "YDS", "4,200" ], [ "TD", 31 ], [ "INT", 9 ] ], player.draft_stat_groups.first[:stats]
    assert_equal [ [ "ATT", 61 ], [ "YDS", "302" ], [ "YPG", "17.8" ] ], player.draft_stat_groups.second[:stats]
    assert_equal [ [ "PASS", 31 ], [ "RUSH", 4 ] ], player.draft_touchdown_stats
    assert_nil player.receiving_stat_line
    assert_nil player.kicking_stat_line
    assert_equal 329.2, player.actual_fantasy_points(ppr: 1)
  end

  test "receivers show rushing production at 50 yards" do
    player = players(:two)
    player.position = "WR"
    player.stats_season = 2025
    player.actual_stats = {
      "games" => 17, "receptions" => 80, "targets" => 120, "receiving_yards" => 1_100,
      "receiving_tds" => 8, "carries" => 3, "rushing_yards" => 14, "rushing_tds" => 0
    }

    assert_equal [ "Rec" ], player.draft_stat_lines.map(&:first)
    assert_equal [ [ "REC", 80 ], [ "TGT", 120 ], [ "YDS", "1,100" ], [ "YPG", "64.7" ] ], player.draft_stat_groups.first[:stats]
    assert_equal [ [ "REC", 8 ] ], player.draft_touchdown_stats

    player.actual_stats["rushing_yards"] = 50
    assert_equal [ "Rec", "Rush" ], player.draft_stat_lines.map(&:first)
  end

  test "orders running back touchdowns rushing before receiving" do
    player = players(:two)
    player.actual_stats = {
      "games" => 17, "carries" => 200, "rushing_yards" => 1_000, "rushing_tds" => 9,
      "receptions" => 50, "targets" => 65, "receiving_yards" => 400, "receiving_tds" => 3
    }
    player.stats_season = 2025

    assert_equal [ [ "RUSH", 9 ], [ "REC", 3 ] ], player.draft_touchdown_stats
  end

  test "receivers show rushing production with a touchdown" do
    player = players(:two)
    player.position = "TE"
    player.stats_season = 2025
    player.actual_stats = {
      "games" => 17, "receptions" => 70, "targets" => 90, "receiving_yards" => 850,
      "receiving_tds" => 7, "carries" => 12, "rushing_yards" => 49, "rushing_tds" => 0
    }

    assert_equal [ "Receiving" ], player.draft_stat_groups.map { |group| group[:label] }

    player.actual_stats["rushing_tds"] = 1
    assert_equal [ "Receiving", "Rushing" ], player.draft_stat_groups.map { |group| group[:label] }
  end

  test "adds reception scoring to actual fantasy points" do
    player = players(:two)
    player.actual_stats = { "fantasy_points" => 180.0, "receptions" => 60 }
    player.stats_season = 2025

    assert_equal 210.0, player.actual_fantasy_points(ppr: 0.5)
  end
end
