require "test_helper"

class McpApiTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get mcp_leagues_path, as: :json

    assert_response :unauthorized
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
end

class McpApiTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end
end
