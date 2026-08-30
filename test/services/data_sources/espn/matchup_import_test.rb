require "test_helper"

module DataSources
  module Espn
    class MatchupImportTest < ActiveSupport::TestCase
      Matchup = LeagueSnapshot::Matchup

      setup do
        @league = League.create!(name: "Matchup Import League", season: 2026)
        @season = @league.espn_seasons.create!(season: 2026, name: "2026", team_count: 2, settings: {}, teams: [], synced_at: Time.current)
        1.upto(2) do |team_id|
          franchise = @league.espn_franchises.create!(key: "T#{team_id}", name: "Team #{team_id}", aliases: [ "T#{team_id}" ])
          @season.team_seasons.create!(
            espn_franchise: franchise, espn_team_id: team_id, team_name: "Team #{team_id}",
            team_abbreviation: "T#{team_id}", owner_ids: [], owner_names: []
          )
        end
      end

      test "upserts games and handles byes ties and unplayed matchups" do
        matchups = [
          matchup(id: 1, home_team_id: 1, away_team_id: nil, home_points: 3, away_points: nil, winner: "UNDECIDED", tier: "WINNERS_BRACKET"),
          matchup(id: 2, home_team_id: 1, away_team_id: 2, home_points: 10, away_points: 10, winner: "TIE"),
          matchup(id: 3, home_team_id: 2, away_team_id: 1, home_points: nil, away_points: nil, winner: "UNDECIDED")
        ]

        MatchupImport.new(season: @season, matchups:).call

        assert_nil @season.matchups.find_by!(espn_matchup_id: 1).away_espn_team_season
        assert_equal 0, @season.matchups.find_by!(espn_matchup_id: 2).margin
        assert_nil @season.matchups.find_by!(espn_matchup_id: 3).margin

        updated = [ matchups.first, matchup(id: 2, home_team_id: 1, away_team_id: 2, home_points: 12, away_points: 10, winner: "HOME") ]
        MatchupImport.new(season: @season, matchups: updated).call

        assert_equal 2, @season.matchups.count
        assert_equal 2, @season.matchups.find_by!(espn_matchup_id: 2).margin
      end

      private

      def matchup(id:, home_team_id:, away_team_id:, home_points:, away_points:, winner:, tier: "NONE")
        Matchup.new(
          id:, matchup_period: 1, scoring_period: 1, playoff_tier: tier,
          home_team_id:, away_team_id:,
          home_points: home_points && BigDecimal(home_points.to_s),
          away_points: away_points && BigDecimal(away_points.to_s),
          winner:
        )
      end
    end
  end
end
