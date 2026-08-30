require "test_helper"

class EspnMatchupTest < ActiveSupport::TestCase
  test "separates regular season, winners bracket, and consolation games" do
    season = espn_seasons(:one)
    home = espn_team_seasons(:one)
    away_franchise = season.league.espn_franchises.create!(key: "AWAY", name: "Away", aliases: [ "AWY" ])
    away = season.team_seasons.create!(
      espn_franchise: away_franchise, espn_team_id: 2, team_name: "Away",
      team_abbreviation: "AWY", owner_ids: [], owner_names: []
    )
    season.matchups.delete_all
    regular = season.matchups.create!(espn_matchup_id: 1, matchup_period: 1, playoff_tier: "NONE", home_espn_team_season: home, away_espn_team_season: away, winner: "HOME")
    season.matchups.create!(espn_matchup_id: 2, matchup_period: 2, playoff_tier: "WINNERS_BRACKET", home_espn_team_season: home, away_espn_team_season: away, winner: "AWAY")
    season.matchups.create!(espn_matchup_id: 3, matchup_period: 3, playoff_tier: "LOSERS_CONSOLATION_LADDER", home_espn_team_season: home, away_espn_team_season: away, winner: "TIE")

    assert_equal [ regular ], season.matchups.regular_season.to_a
    assert_equal 1, season.matchups.winners_bracket.count
    assert_equal 1, season.matchups.consolation.count
    assert_equal 3, EspnMatchup.for_franchise(home.espn_franchise).count
  end
end
