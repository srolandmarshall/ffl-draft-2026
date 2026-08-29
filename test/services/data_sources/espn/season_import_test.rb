require "test_helper"

module DataSources
  module Espn
    class SeasonImportTest < ActiveSupport::TestCase
      FakeSettings = Struct.new(:raw_snapshot)

      FakeSnapshot = Struct.new(:season, :name, :teams, :settings, :picks) do
        def draft_picks(player_catalog:)
          picks
        end
      end

      setup do
        @league = League.create!(name: "Season Import League", season: 2026)
      end

      def build_pick(overall_number:, team_id: 1, team_name: "Red Hawks", team_abbreviation: "RED", owner_ids: [ 501 ], player_id: 100, player_name: "Some Player", position: "RB")
        LeagueSnapshot::DraftPick.new(
          overall_number:, round: 1, round_pick: overall_number, team_id:, team_name:, team_abbreviation:,
          team_owner_ids: owner_ids, player_id:, player_name:, position:
        )
      end

      test "creates a new season with its settings, team roster, and resolved draft picks" do
        identity = LeagueSnapshot::TeamIdentity.new(
          id: 1, name: "Red Hawks", abbreviation: "RED", owner_ids: [ 501 ],
          owner_names: [ "Riley" ], final_rank: 7
        )
        snapshot = FakeSnapshot.new(2026, "2026 Season", [ identity ], FakeSettings.new({ "scoringPeriod" => 1 }), [ build_pick(overall_number: 1) ])

        season = SeasonImport.new(league: @league, snapshot:, player_catalog: nil).call

        assert_equal 2026, season.season
        assert_equal "2026 Season", season.name
        assert_equal 1, season.team_count
        assert_equal({ "scoringPeriod" => 1 }, season.settings)
        pick = season.draft_picks.sole
        assert_equal "Some Player", pick.player_name
        assert_equal @league.espn_franchises.sole, pick.espn_franchise
        team_season = season.team_seasons.sole
        assert_equal pick.espn_franchise, team_season.espn_franchise
        assert_equal [ 501 ], team_season.owner_ids
        assert_equal 7, team_season.espn_final_rank
        assert_nil team_season.regular_season_rank
        assert_nil team_season.playoff_finish
      end

      test "replaces all draft picks on re-import instead of appending to them" do
        snapshot = FakeSnapshot.new(2026, "2026 Season", [ { "id" => 1 } ], FakeSettings.new({}), [ build_pick(overall_number: 1, player_name: "First Import Player") ])
        SeasonImport.new(league: @league, snapshot:, player_catalog: nil).call

        resnapshot = FakeSnapshot.new(2026, "2026 Season", [ { "id" => 1 } ], FakeSettings.new({}), [ build_pick(overall_number: 1, player_name: "Second Import Player") ])
        season = SeasonImport.new(league: @league, snapshot: resnapshot, player_catalog: nil).call

        assert_equal 1, season.draft_picks.count
        assert_equal "Second Import Player", season.draft_picks.sole.player_name
      end

      test "updates an existing season in place instead of creating a duplicate" do
        snapshot = FakeSnapshot.new(2026, "Original Name", [ { "id" => 1 } ], FakeSettings.new({}), [])
        SeasonImport.new(league: @league, snapshot:, player_catalog: nil).call

        renamed_snapshot = FakeSnapshot.new(2026, "Renamed", [ { "id" => 1 } ], FakeSettings.new({}), [])
        SeasonImport.new(league: @league, snapshot: renamed_snapshot, player_catalog: nil).call

        assert_equal 1, @league.espn_seasons.count
        assert_equal "Renamed", @league.espn_seasons.sole.name
      end

      test "reuses the same franchise across two draft picks for the same team in one season" do
        snapshot = FakeSnapshot.new(2026, "2026 Season", [ { "id" => 1 } ], FakeSettings.new({}), [
          build_pick(overall_number: 1, player_id: 100, player_name: "Player One"),
          build_pick(overall_number: 2, player_id: 200, player_name: "Player Two")
        ])

        SeasonImport.new(league: @league, snapshot:, player_catalog: nil).call

        assert_equal 1, @league.espn_franchises.count
        assert_equal 1, @league.espn_team_seasons.count
      end
    end
  end
end
