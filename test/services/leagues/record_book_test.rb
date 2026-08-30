require "test_helper"

module Leagues
  class RecordBookTest < ActiveSupport::TestCase
    setup do
      @league = leagues(:one)
      @newer = espn_seasons(:one)
      @newer.update!(season: 2025, synced_at: Time.zone.parse("2026-01-02 12:00:00"))
      @older = @league.espn_seasons.create!(
        season: 2024, name: "Example 2024", team_count: 2,
        settings: {}, teams: [], synced_at: Time.zone.parse("2025-01-02 12:00:00")
      )
      @first = espn_franchises(:one)
      @first.update!(name: "First Franchise")
      @second = @league.espn_franchises.create!(key: "SECOND", name: "Second Franchise", aliases: [ "TWO" ])

      @first_newer = espn_team_seasons(:one)
      @first_newer.update!(
        espn_franchise: @first, regular_season_rank: 12, espn_final_rank: 7,
        playoff_seed: nil, playoff_finish: nil, wins: 2, losses: 11, ties: 0,
        points_for: 1_100, points_against: 1_300
      )
      @second_newer = team_season(@newer, @second, 2, rank: 1, final_rank: 1, finish: 1, wins: 10, losses: 3)
      @first_older = team_season(@older, @first, 1, rank: 1, final_rank: 1, finish: 2, wins: 8, losses: 5)
      @second_older = team_season(@older, @second, 2, rank: 2, final_rank: 2, finish: 1, wins: 9, losses: 4)

      matchup(@older, 11, @first_older, @second_older, "NONE", "HOME", 110, 100)
      matchup(@older, 12, @first_older, @second_older, "WINNERS_BRACKET", "AWAY", 90, 120)
      matchup(@newer, 13, @first_newer, @second_newer, "LOSERS_CONSOLATION_LADDER", "HOME", 130, 80)
    end

    test "builds regular-season records and playoff resumes from canonical team seasons" do
      book = RecordBook.new(@league).call
      first = book.records.find { |record| record.franchise == @first }
      second = book.records.find { |record| record.franchise == @second }

      assert_equal [ 10, 16, 0 ], [ first.wins, first.losses, first.ties ]
      assert_equal 1, first.playoff_appearances
      assert_equal 0, first.championships
      assert_equal 1, first.runner_ups
      assert_equal 2, second.championships
      assert_equal 1, second.regular_season_titles
      assert_equal @second, book.records.first.franchise
    end

    test "compares each regular-season champion with the actual playoff champion" do
      outcomes = RecordBook.new(@league).call.championship_outcomes.index_by(&:season)

      assert outcomes.fetch(2025).same_franchise?
      assert_not outcomes.fetch(2024).same_franchise?
      assert_equal @first, outcomes.fetch(2024).regular_season_champion
      assert_equal @second, outcomes.fetch(2024).champion
    end

    test "includes every tier in head-to-head while splitting tier counts" do
      series = RecordBook.new(@league).call.head_to_head.sole

      assert_equal 3, series.games
      assert_equal [ 2, 1, 0 ], [ series.wins_a, series.wins_b, series.ties ]
      assert_equal [ 1, 1, 1 ], [ series.regular_season_games, series.playoff_games, series.consolation_games ]
      assert_equal 50.to_d, series.largest_margin
      assert_equal 10.to_d, series.closest_margin
      assert_equal @first, series.leader
    end

    test "finds consecutive playoff runs without treating a consolation rank as a playoff result" do
      book = RecordBook.new(@league).call

      arc = book.dynasties.sole
      assert_equal @second, arc.franchise
      assert_equal [ 2024, 2025 ], arc.seasons
      assert_equal 2, arc.championships

      delta = book.consolation_deltas.sole
      assert_equal @first, delta.franchise
      assert_equal 12, delta.regular_season_rank
      assert_equal 7, delta.espn_final_rank
      assert_equal 5, delta.places
      assert_not_includes book.dynasties.map(&:franchise), @first
    end

    test "cache key changes when the archive is synced again" do
      before = RecordBook.cache_key(@league)
      @newer.update!(synced_at: @newer.synced_at + 1.second)

      assert_not_equal before, RecordBook.cache_key(@league)
    end

    private

    def team_season(season, franchise, team_id, rank:, final_rank:, finish:, wins:, losses:)
      season.team_seasons.create!(
        espn_franchise: franchise, espn_team_id: team_id,
        team_name: franchise.name, team_abbreviation: "T#{team_id}",
        owner_ids: [], owner_names: [], regular_season_rank: rank,
        playoff_seed: rank, playoff_finish: finish, espn_final_rank: final_rank,
        wins:, losses:, ties: 0, points_for: wins * 100, points_against: losses * 100
      )
    end

    def matchup(season, id, home, away, tier, winner, home_points, away_points)
      season.matchups.create!(
        espn_matchup_id: id, matchup_period: id, scoring_period: id,
        playoff_tier: tier, winner:, home_espn_team_season: home,
        away_espn_team_season: away, home_points:, away_points:,
        margin: (home_points - away_points).abs
      )
    end
  end
end
