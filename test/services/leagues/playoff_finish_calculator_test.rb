require "test_helper"

module Leagues
  class PlayoffFinishCalculatorTest < ActiveSupport::TestCase
    test "does not guess finishes from an incomplete bracket" do
      league = League.create!(name: "Incomplete Bracket League", season: 2026)
      season = league.espn_seasons.create!(
        season: 2026, name: "2026", team_count: 6,
        settings: { "scheduleSettings" => { "playoffTeamCount" => 6 } }, teams: [], synced_at: Time.current
      )
      teams = 1.upto(6).map do |seed|
        franchise = league.espn_franchises.create!(key: "T#{seed}", name: "Team #{seed}", aliases: [ "T#{seed}" ])
        season.team_seasons.create!(
          espn_franchise: franchise, espn_team_id: seed, team_name: "Team #{seed}",
          team_abbreviation: "T#{seed}", owner_ids: [], owner_names: [],
          regular_season_rank: seed, playoff_seed: seed, playoff_finish: seed == 1 ? 1 : nil
        )
      end
      season.matchups.create!(
        espn_matchup_id: 1, matchup_period: 15, playoff_tier: "WINNERS_BRACKET",
        home_espn_team_season: teams[2], away_espn_team_season: teams[5], winner: "HOME"
      )

      assert_equal 0, PlayoffFinishCalculator.new(season:).call
      assert season.team_seasons.where.not(playoff_finish: nil).none?
    end
  end
end
