module Mcp
  class LeaguesController < BaseController
    before_action :set_league, only: %i[show history standings matchups records]

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

    private

    def set_league
      @league = visible_leagues.includes(:teams, drafts: :picks).find(params[:id])
    end
  end
end
