require "test_helper"

module DataSources
  module Rankings
    class LeagueLogsTest < ActiveSupport::TestCase
      test "builds a provider-neutral snapshot from player and market payloads" do
        client = Object.new
        client.define_singleton_method(:fetch_players) do
          {
            "data" => [
              { "sleeperPlayerId" => "4046", "firstName" => "Alex", "lastName" => "Archer", "position" => "QB", "team" => "ATL", "espnId" => "1" }
            ]
          }
        end
        client.define_singleton_method(:fetch_market) do |profile:|
          {
            "_attribution" => { "text" => "Powered by LeagueLogs API", "url" => "https://leaguelogs.com" },
            "meta" => { "playerCount" => 2 },
            "data" => [
              { "sleeperPlayerId" => "4046", "overallRank" => 7, "positionRank" => 2, "value" => 91.5 },
              { "sleeperPlayerId" => "missing", "overallRank" => 8, "positionRank" => 3, "value" => 90.0 }
            ],
            "profile" => profile
          }
        end

        snapshot = LeagueLogs.new(client:, profile: "redraft-1qb-12t-ppr1").call
        entry = snapshot.entries.sole

        assert_equal "league_logs", snapshot.source
        assert_equal %w[QB RB WR TE], snapshot.positions
        assert_equal 2, snapshot.meta["market_rows"]
        assert_equal "Powered by LeagueLogs API", snapshot.attribution["text"]
        assert_equal 1, entry.espn_id
        assert_equal "Alex Archer", entry.name
        assert_equal 7, entry.ranking
        assert_equal 2, entry.position_rank
        assert_equal 91.5, entry.value
      end

      test "selects the closest supported profile for a league" do
        league = leagues(:one)
        league.qb_slots = 1
        league.ppr = 0.5
        assert_equal "redraft-1qb-12t-ppr0_5", LeagueLogs.default_profile(league)

        league.qb_slots = 2
        assert_equal "redraft-2qb-12t-ppr1", LeagueLogs.default_profile(league)
      end
    end
  end
end
