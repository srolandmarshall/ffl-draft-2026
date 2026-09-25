require "test_helper"

module Leagues
  class SuperlativesTest < ActiveSupport::TestCase
    setup do
      @league = leagues(:one)
      @season = espn_seasons(:one)
      @season.update!(season: 2025)
      @first = espn_franchises(:one)
      @second = @league.espn_franchises.create!(key: "SECOND", name: "Second Franchise", aliases: [ "TWO" ])
      @home = espn_team_seasons(:one)
      @home.update!(espn_franchise: @first)
      @away = team_season(@second, 2)
      EspnMatchup.delete_all
    end

    test "ranks the biggest week, the closest game, and the widest margin" do
      matchup(1, 150.5, 90.25)
      matchup(2, 100.0, 99.9)
      matchup(3, 120.0, 118.0)

      book = Superlatives.call(@league)

      assert_equal 150.5, book.highest_scores.first.points.to_f
      assert_equal @home, book.highest_scores.first.team_season
      assert_in_delta 0.1, book.closest_games.first.margin.to_f, 0.001
      assert_in_delta 60.25, book.largest_margins.first.margin.to_f, 0.001
      assert_in_delta 240.75, book.highest_combined.first.combined.to_f, 0.001
    end

    test "ignores matchups that have not been played" do
      matchup(1, 150.5, 90.25)
      matchup(2, 0, 0, winner: "UNDECIDED")

      book = Superlatives.call(@league)

      assert_equal [ 90.25, 150.5 ], book.highest_scores.map { |entry| entry.points.to_f }.sort
      assert_in_delta 60.25, book.closest_games.first.margin.to_f, 0.001
    end

    test "reports every franchise's own best week" do
      matchup(1, 150.5, 90.25)
      matchup(2, 80.0, 140.0)

      book = Superlatives.call(@league)

      assert_in_delta 150.5, book.best_week_for(@first).points.to_f, 0.001
      assert_in_delta 140.0, book.best_week_for(@second).points.to_f, 0.001
    end

    private

    def team_season(franchise, team_id)
      @season.team_seasons.create!(
        espn_franchise: franchise, espn_team_id: team_id,
        team_name: franchise.name, team_abbreviation: "T#{team_id}",
        owner_ids: [], owner_names: [], wins: 1, losses: 1, ties: 0,
        points_for: 100, points_against: 100
      )
    end

    def matchup(id, home_points, away_points, winner: nil)
      @season.matchups.create!(
        espn_matchup_id: id, matchup_period: id, scoring_period: id,
        playoff_tier: EspnMatchup::REGULAR_SEASON,
        winner: winner || (home_points >= away_points ? "HOME" : "AWAY"),
        home_espn_team_season: @home, away_espn_team_season: @away,
        home_points:, away_points:, margin: (home_points - away_points).abs
      )
    end
  end
end
