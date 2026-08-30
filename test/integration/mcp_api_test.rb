require "test_helper"

class McpApiTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    paths = [
      mcp_leagues_path,
      history_mcp_league_path(leagues(:one)),
      standings_mcp_league_path(leagues(:one)),
      matchups_mcp_league_path(leagues(:one)),
      records_mcp_league_path(leagues(:one))
    ]

    paths.each do |path|
      get path, as: :json
      assert_response :unauthorized, "expected #{path} to require authentication"
    end
  end

  test "lists only leagues visible to the member" do
    sign_in_as users(:member)

    get mcp_leagues_path, as: :json

    assert_response :success
    body = response.parsed_body
    assert_equal [ leagues(:one).id ], body.fetch("leagues").map { |league| league.fetch("id") }
    assert_equal "Sunday League", body.fetch("leagues").sole.fetch("name")
  end

  test "member cannot read another league's context" do
    sign_in_as users(:member)

    get mcp_league_path(leagues(:two))

    assert_response :not_found
    assert_equal({ "error" => "not_found" }, response.parsed_body)
  end

  test "returns league context and imported history" do
    sign_in_as users(:member)

    get mcp_league_path(leagues(:one)), as: :json
    assert_response :success
    assert_equal [ "Red Hawks" ], response.parsed_body.fetch("teams").map { |team| team.fetch("name") }

    get history_mcp_league_path(leagues(:one)), as: :json
    assert_response :success
    season = response.parsed_body.fetch("seasons").sole
    assert_equal 2025, season.fetch("season")
    assert_equal "MyString", season.fetch("picks").sole.fetch("player")
    standing = season.fetch("standings").sole
    assert_equal 1, standing.fetch("regular_season_rank")
    assert_equal 1, standing.fetch("playoff_finish")
    assert_equal "Champion", standing.fetch("playoff_result")
    assert_not standing.key?("final_rank")
    assert_equal "MyString", season.fetch("champion").fetch("team")
    assert_equal "MyString", season.fetch("regular_season_champion").fetch("team")

    get history_mcp_league_path(leagues(:one)), params: { picks: false }, as: :json
    assert_response :success
    assert_not response.parsed_body.fetch("seasons").sole.key?("picks")
  end

  test "returns canonical standings matchups and all-time records" do
    context = create_history_context
    sign_in_as users(:member)

    get standings_mcp_league_path(leagues(:one)), params: { season: 2025 }, as: :json
    assert_response :success
    standings = response.parsed_body.fetch("seasons").sole.fetch("standings")
    assert_equal [ 1, 12 ], standings.map { |standing| standing.fetch("regular_season_rank") }
    non_qualifier = standings.last
    assert_nil non_qualifier.fetch("playoff_finish")
    assert_equal "Missed the playoffs", non_qualifier.fetch("playoff_result")
    assert_not non_qualifier.key?("final_rank")

    get matchups_mcp_league_path(leagues(:one)), params: { season: 2025, tier: "consolation" }, as: :json
    assert_response :success
    matchup = response.parsed_body.fetch("matchups").sole
    assert_equal EspnMatchup::CONSOLATION_TIERS.first, matchup.fetch("tier")
    assert_equal context.fetch(:second).name, matchup.dig("away", "franchise", "name")

    get records_mcp_league_path(leagues(:one)), as: :json
    assert_response :success
    body = response.parsed_body
    first_record = body.fetch("records").find { |record| record.dig("franchise", "id") == context.fetch(:first).id }
    assert_equal 2, first_record.fetch("wins")
    assert_equal 1, body.fetch("head_to_head").size
    assert_equal 1, body.fetch("rivalries").size
    audit = body.fetch("consolation_rank_audit").sole
    assert_equal 12, audit.fetch("regular_season_rank")
    assert_equal 7, audit.fetch("espn_final_rank")
    assert_equal true, body.fetch("championship_outcomes").sole.fetch("same_franchise")
  end

  test "new history endpoints respect visible leagues" do
    sign_in_as users(:member)

    [
      standings_mcp_league_path(leagues(:two)),
      matchups_mcp_league_path(leagues(:two)),
      records_mcp_league_path(leagues(:two))
    ].each do |path|
      get path, as: :json
      assert_response :not_found, "expected #{path} to enforce league visibility"
    end
  end

  test "returns draft status, results, and player list through the namespace" do
    draft = drafts(:one)
    draft.picks.create!(team: teams(:one), player: players(:one), round: 1, overall_number: 1)
    sign_in_as users(:member)

    get mcp_draft_path(draft.public_id), as: :json
    assert_response :success
    assert_equal 1, response.parsed_body.dig("draft", "picks_made")
    assert_equal "Red Hawks", response.parsed_body.fetch("teams").sole.fetch("name")

    get results_mcp_draft_path(draft.public_id), as: :json
    assert_response :success
    assert_equal "Alex Archer", response.parsed_body.fetch("picks").sole.dig("player", "name")

    get players_mcp_draft_path(draft.public_id), as: :json
    assert_response :success
    assert_equal true, response.parsed_body.fetch("players").find { |player| player["name"] == "Alex Archer" }.fetch("drafted")
  end

  test "bearer token can read the namespace" do
    token = ApiToken.issue!(user: users(:member), label: "draft assistant")

    get mcp_leagues_path, headers: { "Authorization" => "Bearer #{token}" }, as: :json

    assert_response :success
    assert_equal "Sunday League", response.parsed_body.fetch("leagues").sole.fetch("name")
  end

  test "bearer token works without an accept header" do
    token = ApiToken.issue!(user: users(:member))

    get mcp_leagues_path, headers: { "Authorization" => "Bearer #{token}" }

    assert_response :success
    assert_equal "application/json", response.media_type
  end

  test "unknown resources return JSON errors" do
    sign_in_as users(:member)

    get mcp_league_path(999_999)

    assert_response :not_found
    assert_equal({ "error" => "not_found" }, response.parsed_body)

    get mcp_draft_path("missing-draft")

    assert_response :not_found
    assert_equal({ "error" => "not_found" }, response.parsed_body)
  end

  test "member cannot read a draft their team did not enter" do
    outsider = User.create!(email: "outsider@example.com")
    excluded_team = Team.create!(league: leagues(:one), name: "Green Owls", owner_name: "Oakley", abbreviation: "GRN")
    excluded_team.team_memberships.create!(user: outsider)
    sign_in_as outsider

    [
      mcp_draft_path(drafts(:one).public_id),
      results_mcp_draft_path(drafts(:one).public_id),
      players_mcp_draft_path(drafts(:one).public_id)
    ].each do |path|
      get path
      assert_response :not_found, "expected #{path} to enforce draft participation"
    end
  end

  test "completed drafts have no pending pick" do
    draft = drafts(:one)
    draft.update!(status: :complete)
    sign_in_as users(:member)

    get mcp_draft_path(draft.public_id)

    assert_response :success
    assert_nil response.parsed_body.dig("draft", "next_overall_pick")
    assert_nil response.parsed_body.dig("draft", "current_round")
  end

  test "member cannot read another league's draft" do
    sign_in_as users(:member)

    get mcp_draft_path(drafts(:two).public_id), as: :json

    assert_response :not_found
  end

  private

  def create_history_context
    season = espn_seasons(:one)
    first = espn_franchises(:one)
    first_team_season = espn_team_seasons(:one)
    first_team_season.update!(
      regular_season_rank: 12, espn_final_rank: 7,
      playoff_seed: nil, playoff_finish: nil,
      wins: 2, losses: 11, ties: 0
    )
    second = season.league.espn_franchises.create!(key: "API-TWO", name: "API Team Two", aliases: [ "TWO" ])
    second_team_season = season.team_seasons.create!(
      espn_franchise: second, espn_team_id: 2,
      team_name: second.name, team_abbreviation: "TWO",
      owner_ids: [], owner_names: [], regular_season_rank: 1,
      playoff_seed: 1, playoff_finish: 1, espn_final_rank: 1,
      wins: 10, losses: 3, ties: 0, points_for: 1_400, points_against: 1_100
    )
    season.matchups.create!(
      espn_matchup_id: 81, matchup_period: 15, scoring_period: 15,
      playoff_tier: EspnMatchup::CONSOLATION_TIERS.first, winner: "AWAY",
      home_espn_team_season: first_team_season, away_espn_team_season: second_team_season,
      home_points: 90, away_points: 110, margin: 20
    )
    { first:, second: }
  end
end

class McpApiTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end
end
