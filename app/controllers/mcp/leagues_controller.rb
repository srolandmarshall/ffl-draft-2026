module Mcp
  class LeaguesController < BaseController
    before_action :set_league, only: %i[show history standings matchups records player_scores lineups]

    def index
      leagues = visible_leagues.order(:season, :name).preload(drafts: %i[draft_entries picks])
      render_json(leagues: leagues.map { |league| Mcp::LeagueData.new(league).summary })
    end

    def show
      render_json(Mcp::LeagueData.new(@league).detail)
    end

    def history
      render_json(Mcp::LeagueData.new(@league, season: params[:season], include_picks: params[:picks].to_s != "false").history)
    end

    def standings
      render_json(Mcp::LeagueData.new(@league, season: params[:season]).standings)
    end

    def matchups
      render_json(Mcp::LeagueData.new(@league, season: params[:season]).matchups(tier: params[:tier]))
    end

    def records
      render_json(Mcp::LeagueData.new(@league).records)
    end

    def player_scores
      render_json(Mcp::LeagueData.new(@league, season: params[:season]).player_scores)
    end

    def lineups
      return render_missing_espn_league unless @league.espn_league_id.present?

      scoring_period = requested_scoring_period
      return render_invalid_scoring_period if params[:scoring_period].present? && scoring_period.nil?

      snapshot = espn_client.fetch_league_lineups(
        year: @league.season,
        league_id: @league.espn_league_id,
        scoring_period:
      )
      render_json(Mcp::LineupData.new(@league, snapshot).as_json)
    rescue DataSources::HttpError => error
      render json: { error: "espn_unavailable", message: error.message }, status: :bad_gateway
    end

    private

    def set_league
      @league = visible_leagues.includes(:teams, drafts: :picks).find(params[:id])
    end

    def requested_scoring_period
      return if params[:scoring_period].blank?

      value = Integer(params[:scoring_period], exception: false)
      value if value&.positive?
    end

    def render_missing_espn_league
      render json: { error: "espn_league_not_configured" }, status: :unprocessable_entity
    end

    def render_invalid_scoring_period
      render json: { error: "invalid_scoring_period" }, status: :unprocessable_entity
    end
  end
end
