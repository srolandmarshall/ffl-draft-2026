require "test_helper"

module DataSources
  module Espn
    class StandingsImportTest < ActiveSupport::TestCase
      setup do
        @league = League.create!(name: "Standings League", season: 2026)
        @season = @league.espn_seasons.create!(
          season: 2025, name: "2025", team_count: 4,
          settings: { "scheduleSettings" => { "matchupPeriodCount" => 1, "playoffTeamCount" => 2 } },
          teams: [], synced_at: Time.current
        )
        @teams = 1.upto(4).map do |team_id|
          franchise = @league.espn_franchises.create!(key: "T#{team_id}", name: "Team #{team_id}", aliases: [ "T#{team_id}" ])
          @season.team_seasons.create!(
            espn_franchise: franchise, espn_team_id: team_id, team_name: "Team #{team_id}",
            team_abbreviation: "T#{team_id}", owner_ids: [], owner_names: []
          )
        end
        create_matchup(1, @teams[0], @teams[1], 100, 90, "HOME", "NONE", 1)
        create_matchup(2, @teams[2], @teams[3], 120, 80, "HOME", "NONE", 1)
        create_matchup(3, @teams[1], @teams[0], 200, 50, "HOME", "LOSERS_CONSOLATION_LADDER", 2)
      end

      test "ranks complete regular seasons by wins then points and excludes consolation" do
        StandingsImport.new(season: @season, identities: @teams.map { |team| { "id" => team.espn_team_id } }).call

        assert_equal [ 3, 1, 2, 4 ], @season.team_seasons.reorder(:regular_season_rank).pluck(:espn_team_id)
        first = @teams.first.reload
        assert_equal "1-0-0", first.record
        assert_equal 100, first.points_for
        assert_equal 90, first.points_against
        assert_equal 2, first.playoff_seed
        assert_nil @teams.last.reload.playoff_seed
      end

      private

      def create_matchup(id, home, away, home_points, away_points, winner, tier, period)
        @season.matchups.create!(
          espn_matchup_id: id, matchup_period: period, playoff_tier: tier,
          home_espn_team_season: home, away_espn_team_season: away,
          home_points:, away_points:, margin: (home_points - away_points).abs, winner:
        )
      end
    end
  end
end
