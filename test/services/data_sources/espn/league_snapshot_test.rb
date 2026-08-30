require "test_helper"

module DataSources
  module Espn
    class LeagueSnapshotTest < ActiveSupport::TestCase
      test "parses pre-2018 standings and matchup tiers" do
        snapshot = snapshot_from_fixture(2016)

        assert_equal 2016, snapshot.season
        assert_equal 12, snapshot.teams.size
        team = snapshot.teams.find { |identity| identity.id == 1 }
        assert_equal 5, team.regular_season_rank
        assert_equal 5, team.playoff_seed
        assert_equal [ 8, 5, 0 ], [ team.record.wins, team.record.losses, team.record.ties ]
        assert_equal BigDecimal("1334.38"), team.record.points_for
        assert_equal 5, team.espn_final_rank
        assert_nil team.rank_final
        assert_not_respond_to team, :final_rank

        assert_equal 97, snapshot.matchups.size
        assert_equal(
          %w[LOSERS_CONSOLATION_LADDER NONE WINNERS_BRACKET WINNERS_CONSOLATION_LADDER],
          snapshot.matchups.map(&:playoff_tier).uniq.sort
        )
        bye = snapshot.matchups.find { |matchup| matchup.playoff_tier == "WINNERS_BRACKET" && matchup.away_team_id.nil? }
        assert_equal 14, bye.matchup_period
        assert_nil bye.away_points
      end

      test "treats ESPN playoff seed as a rank but only qualifies the top playoff teams" do
        snapshot = snapshot_from_fixture(2025)
        qualifier = snapshot.teams.find { |identity| identity.regular_season_rank == 6 }
        non_qualifier = snapshot.teams.find { |identity| identity.regular_season_rank == 7 }

        assert_equal 6, qualifier.playoff_seed
        assert_nil non_qualifier.playoff_seed
        assert_equal 103, snapshot.matchups.size
        assert snapshot.matchups.all? { |matchup| matchup.scoring_period.present? }
      end

      private

      def snapshot_from_fixture(year)
        payload = JSON.parse(file_fixture("espn/league_snapshot_#{year}.json").read)
        payload = payload.first if payload.is_a?(Array)
        LeagueSnapshot.from_payload(payload)
      end
    end
  end
end
