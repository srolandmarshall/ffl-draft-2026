module Mcp
  class Server
    PROTOCOL_VERSIONS = %w[2026-07-28 2025-11-25 2025-06-18].freeze

    TOOL_DEFINITIONS = [
      {
        name: "list_leagues",
        title: "List fantasy leagues",
        description: "List the fantasy leagues the authenticated user may read.",
        inputSchema: {
          type: "object",
          properties: {},
          additionalProperties: false
        },
        annotations: {
          readOnlyHint: true,
          destructiveHint: false,
          openWorldHint: false
        }
      },
      {
        name: "get_league",
        title: "Get fantasy league",
        description: "Get teams, rules, drafts, and ESPN sync metadata for one visible league.",
        inputSchema: {
          type: "object",
          properties: {
            league_id: {
              type: "integer",
              description: "Local league ID returned by list_leagues."
            }
          },
          required: ["league_id"],
          additionalProperties: false
        },
        annotations: {
          readOnlyHint: true,
          destructiveHint: false,
          openWorldHint: false
        }
      },
      {
        name: "get_week_snapshot",
        title: "Get weekly league snapshot",
        description: "Fetch live ESPN lineups for every team in a visible league. Use this for weekly roster, waiver, trade, injury, and start/sit analysis.",
        inputSchema: {
          type: "object",
          properties: {
            league_id: {
              type: "integer",
              description: "Local league ID returned by list_leagues."
            },
            scoring_period: {
              type: "integer",
              minimum: 1,
              description: "Optional ESPN scoring period (week). Omit for ESPN's current period."
            }
          },
          required: ["league_id"],
          additionalProperties: false
        },
        annotations: {
          readOnlyHint: true,
          destructiveHint: false,
          openWorldHint: false
        }
      }
    ].freeze

    class ToolError < StandardError; end

    def self.parse_error
      {
        jsonrpc: "2.0",
        id: nil,
        error: { code: -32700, message: "Parse error" }
      }
    end

    def initialize(current_user:, espn_client:)
      @current_user = current_user
      @espn_client = espn_client
    end

    def call(message)
      return invalid_request unless valid_message?(message)

      @request_id = message["id"]
      return [:accepted, nil] if @request_id.nil?

      case message["method"]
      when "initialize"
        success(initialize_result(message.fetch("params", {})))
      when "ping"
        success({})
      when "tools/list"
        success(tools: TOOL_DEFINITIONS)
      when "tools/call"
        success(call_tool(message.fetch("params", {})))
      else
        error(-32601, "Method not found")
      end
    rescue KeyError, TypeError
      error(-32602, "Invalid params")
    end

    private

    attr_reader :current_user, :espn_client

    def valid_message?(message)
      message.is_a?(Hash) &&
        message["jsonrpc"] == "2.0" &&
        message["method"].is_a?(String)
    end

    def invalid_request
      @request_id = nil
      error(-32600, "Invalid Request", status: :bad_request)
    end

    def initialize_result(params)
      requested = params["protocolVersion"]
      protocol_version = PROTOCOL_VERSIONS.include?(requested) ? requested : PROTOCOL_VERSIONS.first

      {
        protocolVersion: protocol_version,
        capabilities: { tools: { listChanged: false } },
        serverInfo: { name: "ffl-draft", version: "1.0.0" },
        instructions: "Use list_leagues to resolve the local league ID, then get_week_snapshot for live weekly roster analysis. All tools are read-only and enforce the signed-in user's league access."
      }
    end

    def call_tool(params)
      name = params.fetch("name")
      arguments = params.fetch("arguments", {})
      data, message = case name
      when "list_leagues"
        [list_leagues, "Listed visible fantasy leagues."]
      when "get_league"
        [get_league(arguments), "Loaded fantasy league."]
      when "get_week_snapshot"
        [get_week_snapshot(arguments), "Fetched live ESPN lineups for the league."]
      else
        raise ToolError, "Unknown tool: #{name}"
      end

      {
        content: [{ type: "text", text: message }],
        structuredContent: data
      }
    rescue ActiveRecord::RecordNotFound
      tool_error("League not found or not visible to this user.")
    rescue DataSources::HttpError => error
      tool_error("ESPN is unavailable: #{error.message}")
    rescue ToolError => error
      tool_error(error.message)
    end

    def list_leagues
      leagues = visible_leagues.order(:season, :name).preload(drafts: %i[draft_entries picks])
      { leagues: leagues.map { |league| Mcp::LeagueData.new(league).summary } }
    end

    def get_league(arguments)
      league = find_league(arguments.fetch("league_id"))
      detail = Mcp::LeagueData.new(league).detail
      detail.merge(viewer: viewer_data(league))
    end

    def get_week_snapshot(arguments)
      league = find_league(arguments.fetch("league_id"))
      raise ToolError, "ESPN league is not configured." if league.espn_league_id.blank?

      scoring_period = arguments["scoring_period"]
      unless scoring_period.nil? || scoring_period.is_a?(Integer) && scoring_period.positive?
        raise ToolError, "scoring_period must be a positive integer."
      end

      snapshot = espn_client.fetch_league_lineups(
        year: league.season,
        league_id: league.espn_league_id,
        scoring_period:
      )

      {
        viewer: viewer_data(league),
        league: Mcp::LeagueData.new(league).detail,
        lineups: Mcp::LineupData.new(league, snapshot).as_json
      }
    end

    def find_league(id)
      visible_leagues.includes(:teams, drafts: :picks).find(id)
    end

    def visible_leagues
      return League.all if current_user.commissioner?

      League.joins(teams: :team_memberships)
        .where(team_memberships: { user_id: current_user.id })
        .distinct
    end

    def viewer_data(league)
      {
        team_ids: league.teams.joins(:team_memberships)
          .where(team_memberships: { user_id: current_user.id })
          .distinct
          .pluck(:id)
      }
    end

    def tool_error(message)
      {
        content: [{ type: "text", text: message }],
        isError: true
      }
    end

    def success(result)
      [
        :ok,
        { jsonrpc: "2.0", id: @request_id, result: }
      ]
    end

    def error(code, message, status: :ok)
      [
        status,
        {
          jsonrpc: "2.0",
          id: @request_id,
          error: { code:, message: }
        }
      ]
    end
  end
end
