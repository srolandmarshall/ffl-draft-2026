require "test_helper"

class McpServerTest < ActionDispatch::IntegrationTest
  setup do
    @base_url = "http://www.example.com"
    @resource = "#{@base_url}/mcp"
  end

  test "publishes OAuth discovery metadata" do
    get mcp_protected_resource_metadata_path

    assert_response :success
    assert_equal @resource, response.parsed_body.fetch("resource")
    assert_equal [@base_url], response.parsed_body.fetch("authorization_servers")

    get oauth_authorization_server_metadata_path

    assert_response :success
    metadata = response.parsed_body
    assert_equal "#{@base_url}/oauth/authorize", metadata.fetch("authorization_endpoint")
    assert_equal "#{@base_url}/oauth/token", metadata.fetch("token_endpoint")
    assert_equal ["S256"], metadata.fetch("code_challenge_methods_supported")
    assert_equal true, metadata.fetch("authorization_response_iss_parameter_supported")
  end

  test "unauthenticated MCP requests return an OAuth discovery challenge" do
    post mcp_server_path,
      params: rpc_request("initialize", protocolVersion: "2025-11-25"),
      as: :json

    assert_response :unauthorized
    assert_includes response.headers.fetch("WWW-Authenticate"), "oauth-protected-resource"
    assert_includes response.headers.fetch("WWW-Authenticate"), "league:read"
  end

  test "OAuth PKCE flow issues refreshable credentials for MCP tools" do
    client = register_client
    verifier = "test-verifier-with-enough-entropy-1234567890"
    challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false)
    sign_in_as users(:member)

    get oauth_authorize_path, params: {
      response_type: "code",
      client_id: client.fetch("client_id"),
      redirect_uri: client.fetch("redirect_uris").sole,
      scope: "league:read",
      resource: @resource,
      state: "opaque-state",
      code_challenge: challenge,
      code_challenge_method: "S256"
    }

    assert_response :success
    request_token = css_select("input[name=oauth_request]").sole.fetch("value")

    post oauth_authorize_path, params: {
      oauth_request: request_token,
      decision: "approve"
    }

    assert_response :redirect
    redirect_params = Rack::Utils.parse_query(URI.parse(response.location).query)
    assert_equal "opaque-state", redirect_params.fetch("state")
    assert_equal @base_url, redirect_params.fetch("iss")

    post oauth_token_path, params: {
      grant_type: "authorization_code",
      code: redirect_params.fetch("code"),
      redirect_uri: client.fetch("redirect_uris").sole,
      client_id: client.fetch("client_id"),
      code_verifier: verifier,
      resource: @resource
    }

    assert_response :success
    tokens = response.parsed_body
    assert tokens.fetch("access_token").start_with?("ffld_oauth_")
    assert tokens.fetch("refresh_token").start_with?("ffld_refresh_")

    post mcp_server_path,
      params: rpc_request("initialize", protocolVersion: "2025-11-25"),
      headers: { "Authorization" => "Bearer #{tokens.fetch("access_token")}" },
      as: :json

    assert_response :success
    assert_equal "ffl-draft", response.parsed_body.dig("result", "serverInfo", "name")

    post mcp_server_path,
      params: rpc_request("tools/call", name: "list_leagues", arguments: {}),
      headers: { "Authorization" => "Bearer #{tokens.fetch("access_token")}" },
      as: :json

    assert_response :success
    leagues = response.parsed_body.dig("result", "structuredContent", "leagues")
    assert_equal [leagues(:one).id], leagues.map { |league| league.fetch("id") }

    post oauth_token_path, params: {
      grant_type: "refresh_token",
      refresh_token: tokens.fetch("refresh_token"),
      client_id: client.fetch("client_id"),
      resource: @resource
    }

    assert_response :success
    assert response.parsed_body.fetch("access_token").start_with?("ffld_oauth_")
  end

  test "week snapshot identifies the viewer's team and returns live lineups" do
    league = leagues(:one)
    league.update!(espn_league_id: "123456")
    teams(:one).update!(espn_team_id: 7)
    token = ApiToken.issue!(user: users(:member))
    fetcher = lambda do |_uri|
      Struct.new(:code, :body).new(
        "200",
        file_fixture("espn/league_lineups.json").read
      )
    end

    post mcp_server_path,
      params: rpc_request(
        "tools/call",
        name: "get_week_snapshot",
        arguments: { league_id: league.id, scoring_period: 3 }
      ),
      headers: { "Authorization" => "Bearer #{token}" },
      env: { "ffl.espn_fetcher" => fetcher },
      as: :json

    assert_response :success
    result = response.parsed_body.dig("result", "structuredContent")
    assert_equal [teams(:one).id], result.dig("viewer", "team_ids")
    assert_equal 3, result.dig("lineups", "scoring_period")
    assert_equal 2, result.dig("lineups", "teams").size
  end

  private

  def register_client
    post oauth_register_path,
      params: {
        client_name: "ChatGPT",
        redirect_uris: ["https://chatgpt.com/connector_platform_oauth_redirect"],
        token_endpoint_auth_method: "none"
      },
      as: :json

    assert_response :created
    response.parsed_body
  end

  def rpc_request(method, params = {})
    {
      jsonrpc: "2.0",
      id: SecureRandom.uuid,
      method:,
      params:
    }
  end
end
