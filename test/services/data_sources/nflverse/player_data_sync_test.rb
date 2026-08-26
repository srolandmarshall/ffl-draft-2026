require "test_helper"

module DataSources
  module Nflverse
    class PlayerDataSyncTest < ActiveSupport::TestCase
      test "matches players by ESPN ID and stores only prior regular-season results" do
        player_rows = [
          { "espn_id" => "1", "gsis_id" => "00-001", "rookie_season" => "2026", "headshot" => "https://static.www.nfl.com/player-one" },
          { "espn_id" => "2", "gsis_id" => "00-002", "rookie_season" => "2024" }
        ]
        stat_rows = [
          { "player_id" => "00-001", "season" => "2025", "season_type" => "REG", "games" => "17", "passing_yards" => "4200", "fantasy_points" => "329.2" },
          { "player_id" => "00-002", "season" => "2025", "season_type" => "POST", "games" => "3", "fantasy_points" => "80" },
          { "player_id" => "00-002", "season" => "2024", "season_type" => "REG", "games" => "17", "fantasy_points" => "200" }
        ]

        result = PlayerDataSync.new(
          player_rows:,
          stat_rows:,
          current_season: 2026,
          stats_season: 2025,
          headshot_fetcher: lambda { |url|
            assert_equal "https://static.www.nfl.com/player-one", url
            Client::DownloadedImage.new(io: StringIO.new("headshot"), content_type: "image/png", extension: "png")
          }
        ).call

        assert_equal 2, result.updated
        assert_equal 1, result.with_stats
        assert_equal 1, result.rookies
        assert_equal 1, result.headshots_cached
        assert_equal 0, result.headshots_failed
        assert players(:one).reload.rookie?
        assert_equal 2025, players(:one).stats_season
        assert_equal 4200, players(:one).actual_stats["passing_yards"]
        assert_equal "https://static.www.nfl.com/player-one", players(:one).headshot_url
        assert players(:one).headshot.attached?
        assert_not players(:two).reload.rookie?
        assert_nil players(:two).actual_stats
      end

      test "updates every player's stats before caching headshots" do
        players(:one).update!(headshot_url: nil)
        players(:two).update!(headshot_url: nil)
        player_rows = [
          { "espn_id" => "1", "gsis_id" => "00-001", "rookie_season" => "2024", "headshot" => "https://example.com/one" },
          { "espn_id" => "2", "gsis_id" => "00-002", "rookie_season" => "2024", "headshot" => "https://example.com/two" }
        ]
        stat_rows = [
          { "player_id" => "00-001", "season" => "2025", "season_type" => "REG", "games" => "17", "fantasy_points" => "100" },
          { "player_id" => "00-002", "season" => "2025", "season_type" => "REG", "games" => "17", "fantasy_points" => "200" }
        ]

        error = assert_raises(RuntimeError) do
          PlayerDataSync.new(
            player_rows:,
            stat_rows:,
            current_season: 2026,
            stats_season: 2025,
            headshot_fetcher: ->(_url) { raise "download failed" }
          ).call
        end

        assert_equal "download failed", error.message
        assert_equal 100, players(:one).reload.actual_stats["fantasy_points"]
        assert_equal 200, players(:two).reload.actual_stats["fantasy_points"]
      end
    end
  end
end
