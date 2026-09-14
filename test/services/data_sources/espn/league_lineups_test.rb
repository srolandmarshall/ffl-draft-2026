require "test_helper"

module DataSources
  module Espn
    class LeagueLineupsTest < ActiveSupport::TestCase
      test "parses all teams and normalizes lineup slots" do
        fetched_at = Time.zone.parse("2026-09-14 13:00:00")
        snapshot = LeagueLineups.from_payload(payload, fetched_at:)

        assert_equal 3, snapshot.scoring_period
        assert_equal fetched_at, snapshot.fetched_at
        assert_equal 2, snapshot.teams.size
        assert_not_includes snapshot.teams.map(&:id), 9

        team = snapshot.teams.first
        assert_equal [ "Example Manager" ], team.owner_names
        starter, bench, injured_reserve = team.entries
        assert_equal [ "QB", "BE", "IR" ], team.entries.map(&:lineup_slot)
        assert_equal [ "starter", "bench", "injured_reserve" ], team.entries.map(&:status)
        assert_equal "Example Quarterback", starter.player.name
        assert_equal "QB", starter.player.position
        assert_equal "CHI", starter.player.pro_team
        assert_equal [ "QB", "BE", "IR" ], starter.player.eligible_positions
        assert_equal 97.25, starter.player.percent_owned
        assert_equal "WAIVER", bench.acquisition_type
        assert_equal "2026-09-12T12:00:00Z", bench.acquired_at
        assert_equal true, injured_reserve.player.injured
      end

      test "uses requested scoring period and preserves unknown slots" do
        snapshot = LeagueLineups.from_payload(payload, scoring_period: 4)
        entry = snapshot.teams.second.entries.sole

        assert_equal 4, snapshot.scoring_period
        assert_equal "ESPN slot #99", entry.lineup_slot
        assert_equal "starter", entry.status
        assert_equal "ESPN Player #9004", entry.player.name
        assert_equal "FA", entry.player.pro_team
      end

      test "raises a source error for malformed roster data" do
        error = assert_raises(HttpError) do
          LeagueLineups.from_payload({ "scoringPeriodId" => 3 }).teams
        end

        assert_equal "ESPN roster response is missing teams", error.message
      end

      private

      def payload
        JSON.parse(file_fixture("espn/league_lineups.json").read)
      end
    end
  end
end
