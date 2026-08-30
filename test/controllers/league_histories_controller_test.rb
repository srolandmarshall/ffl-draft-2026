require "test_helper"

class LeagueHistoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @league = leagues(:one)
    @current_season = @league.espn_seasons.create!(
      season: 2026, name: "Fantasy Year IX", team_count: 12,
      settings: {}, teams: [], synced_at: Time.current
    )
    @season = espn_seasons(:one)
    @season.update!(
      name: "Fantasy Year VIII", team_count: 12, synced_at: Time.current,
      teams: [ { "id" => 7, "name" => "Red Hawks", "abbreviation" => "RED", "owner_ids" => [ "owner-red" ], "final_rank" => 1 } ]
    )
    @season.draft_picks.first.update!(
      espn_team_id: 7, team_name: "Red Hawks", team_abbreviation: "RED",
      espn_player_id: 42, player_name: "Justin Jefferson", position: "WR"
    )
    @older_season = @league.espn_seasons.create!(
      season: 2024, name: "Fantasy Year VII", team_count: 12,
      settings: {},
      teams: [ { "id" => 7, "name" => "Red Hawks", "abbreviation" => "RED", "owner_ids" => [ "owner-red" ], "final_rank" => 2 } ],
      synced_at: Time.current
    )
    @older_season.draft_picks.create!(
      overall_number: 1, round: 1, round_pick: 1,
      espn_team_id: 7, team_name: "Red Hawks", team_abbreviation: "RED",
      espn_player_id: 42, player_name: "Justin Jefferson", position: "WR"
    )
    franchise = espn_franchises(:one)
    franchise.update!(name: "Red Hawks", aliases: [ "RED" ], owner_ids: [ "owner-red" ])
    franchise.draft_picks << @season.draft_picks.first
    franchise.draft_picks << @older_season.draft_picks.first
    espn_team_seasons(:one).update!(
      espn_franchise: franchise, espn_team_id: 7, team_name: "Red Hawks",
      team_abbreviation: "RED", owner_ids: [ "owner-red" ], regular_season_rank: 1, playoff_finish: 1
    )
    @older_season.team_seasons.create!(
      espn_franchise: franchise, espn_team_id: 7, team_name: "Red Hawks",
      team_abbreviation: "RED", owner_ids: [ "owner-red" ], owner_names: [], regular_season_rank: 2, playoff_finish: 2
    )
  end

  test "league member sees active franchise history at the league route" do
    retired = @league.espn_franchises.create!(key: "retired", name: "Retired Team", aliases: [ "OLD" ])
    retired.draft_picks << @older_season.draft_picks.create!(
      overall_number: 2, round: 1, round_pick: 2,
      espn_team_id: 8, team_name: "Retired Team", team_abbreviation: "OLD",
      espn_player_id: 44, player_name: "Retired Player", position: "RB"
    )
    sign_in_as users(:member)

    get league_history_path(@league)

    assert_response :success
    assert_equal "/league/#{@league.id}/history", league_history_path(@league)
    assert_select "h1", text: @league.name
    assert_select "h2", text: "Fantasy Year VIII"
    assert_select "[title*='Justin Jefferson']"
    assert_select "button[role=tab]", count: 2
    assert_select "button[data-year='2025'][aria-selected='true']"
    assert_select "section[role=tabpanel]", count: 2
    assert_select "section[role=tabpanel][hidden]", count: 1
    assert_select "[data-year='2026']", count: 0
    assert_select "h2", text: "Every team leaves a pattern"
    assert_select "h2", text: "Follow one franchise through history"
    assert_select "svg[aria-label='Historical league finishes by team and season']"
    assert_select "circle title", text: /1st regular season · Champion/
    assert_select "circle[stroke='#facc15']", count: 1
    assert_select "[data-controller='finish-chart']"
    assert_select "button[data-finish-chart-target='button'][aria-pressed='true']", count: 1
    assert_select "article [data-round='1']", text: /WR/
    assert_select "article [data-round='1'] [style*='conic-gradient']"
    assert_select "article", text: /Signature/
    assert_select "article", text: /Chaos round/
    assert_select "article", text: /Biggest binge/
    assert_select "article", text: /Wide Receiver Whisperer/, count: 0
    assert_select "article", text: /Loyalty:/
    assert_select "article", text: /Retired Team/, count: 0
  end

  test "orders franchises by championships then years in the league" do
    challenger_team = @league.teams.create!(name: "Challenger", owner_name: "Chally", abbreviation: "CHL")
    challenger = @league.espn_franchises.create!(key: "challenger", name: "Challenger", aliases: [ "CHL" ], team: challenger_team, owner_ids: [ "owner-chl" ])
    espn_team_seasons(:one).update!(regular_season_rank: 2, playoff_finish: 2)
    @season.team_seasons.create!(
      espn_franchise: challenger, espn_team_id: 9, team_name: "Challenger",
      team_abbreviation: "CHL", owner_ids: [ "owner-chl" ], owner_names: [], regular_season_rank: 1, playoff_finish: 1
    )
    @older_season.team_seasons.find_by!(espn_team_id: 7).update!(regular_season_rank: 2, playoff_finish: 2)
    @older_season.team_seasons.create!(
      espn_franchise: challenger, espn_team_id: 9, team_name: "Challenger",
      team_abbreviation: "CHL", owner_ids: [ "owner-chl" ], owner_names: [], regular_season_rank: 1, playoff_finish: 1
    )
    challenger.draft_picks << @season.draft_picks.create!(
      overall_number: 2, round: 1, round_pick: 2,
      espn_team_id: 9, team_name: "Challenger", team_abbreviation: "CHL",
      espn_player_id: 45, player_name: "Challenger Player", position: "RB"
    )
    challenger.draft_picks << @older_season.draft_picks.create!(
      overall_number: 3, round: 1, round_pick: 3,
      espn_team_id: 9, team_name: "Challenger", team_abbreviation: "CHL",
      espn_player_id: 46, player_name: "Challenger Player Two", position: "RB"
    )
    sign_in_as users(:member)

    get league_history_path(@league)

    assert_response :success
    buttons = css_select("button[data-finish-chart-target='button']").map { |node| node["data-name"] }
    assert_equal [ "All franchises", "Challenger", "Red Hawks" ], buttons
  end

  test "keeps an archived team in the all-time book but out of active draft tendencies" do
    teams(:one).update!(archived: true)
    sign_in_as users(:member)

    get league_history_path(@league)

    assert_response :success
    assert_select "button[data-finish-chart-target='button'][data-name='Red Hawks']", count: 0
    assert_select "section[aria-labelledby='record-book-title']", text: /Red Hawks/
    assert_select "h2", text: "Every team leaves a pattern", count: 0
  end

  test "shows the record book rivalry grid standings and winners bracket accessibly" do
    opponent = add_history_opponent
    sign_in_as users(:member)

    get league_history_path(@league)

    assert_response :success
    assert_select "#record-book-title", text: "The all-time record book"
    assert_select "caption.sr-only", text: "All-time regular-season and playoff records by franchise"
    assert_select "#rivalries-title", text: "The rivalries"
    assert_select "#head-to-head-title", text: "Head-to-head ledger"
    assert_select "td[tabindex='0'][aria-label*='regular season'][aria-label*='winners bracket'][aria-label*='consolation']"
    assert_select "#season-#{@season.id}-standings", text: "Regular-season standings"
    assert_select "caption.sr-only", text: "2025 regular-season standings"
    assert_select "[role='list'][aria-label='2025 winners bracket rounds']"
    assert_select "article[aria-label*='#{opponent.name}']"
    assert_select ".overflow-x-auto", minimum: 3
  end

  test "history remains available while regular-season finishes await import" do
    @league.espn_team_seasons.update_all(regular_season_rank: nil)
    sign_in_as users(:member)

    get league_history_path(@league)

    assert_response :success
    assert_select "[data-controller='finish-chart']", count: 0
    assert_select "h2", text: "Every team leaves a pattern"
  end

  test "finish chart plots regular rank and marks the actual playoff champion" do
    espn_team_seasons(:one).update!(regular_season_rank: 2, playoff_finish: 1)
    @older_season.team_seasons.find_by!(espn_team_id: 7).update!(regular_season_rank: 1, playoff_finish: 2)
    sign_in_as users(:member)

    get league_history_path(@league)

    assert_select "circle title", text: /2025 · 2nd regular season · Champion/
    assert_select "circle title", text: /2024 · 1st regular season\z/
    assert_select "circle[stroke='#facc15']", count: 1
  end

  test "current season appears after ESPN has drafted" do
    @current_season.draft_picks.create!(
      overall_number: 1, round: 1, round_pick: 1,
      espn_team_id: 7, team_name: "Red Hawks", team_abbreviation: "RED",
      espn_player_id: 43, player_name: "Ja'Marr Chase", position: "WR"
    )
    sign_in_as users(:member)

    get league_history_path(@league)

    assert_select "button[data-year='2026']"
  end

  test "member of another league cannot see league history" do
    outsider = User.create!(email: "outsider@example.com")
    teams(:two).team_memberships.create!(user: outsider)
    sign_in_as outsider

    get league_history_path(@league)

    assert_redirected_to root_path
  end

  private

  def add_history_opponent
    team = @league.teams.create!(name: "Green Machine", owner_name: "Example Owner", abbreviation: "GRN")
    franchise = @league.espn_franchises.create!(key: "green", name: "Green Machine", aliases: [ "GRN" ], team:)
    team_season = @season.team_seasons.create!(
      espn_franchise: franchise, espn_team_id: 9, team_name: franchise.name,
      team_abbreviation: "GRN", owner_ids: [], owner_names: [],
      regular_season_rank: 2, playoff_seed: 2, playoff_finish: 2,
      wins: 8, losses: 5, ties: 0, points_for: 1_300, points_against: 1_200
    )
    home = @season.team_seasons.find_by!(espn_team_id: 7)
    @season.matchups.create!(
      espn_matchup_id: 91, matchup_period: 15, scoring_period: 15,
      playoff_tier: EspnMatchup::WINNERS_BRACKET, winner: "HOME",
      home_espn_team_season: home, away_espn_team_season: team_season,
      home_points: 120, away_points: 110, margin: 10
    )
    @season.matchups.create!(
      espn_matchup_id: 92, matchup_period: 16, scoring_period: 16,
      playoff_tier: EspnMatchup::CONSOLATION_TIERS.first, winner: "AWAY",
      home_espn_team_season: home, away_espn_team_season: team_season,
      home_points: 90, away_points: 100, margin: 10
    )
    franchise
  end
end
