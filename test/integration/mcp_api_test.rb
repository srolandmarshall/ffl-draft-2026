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
