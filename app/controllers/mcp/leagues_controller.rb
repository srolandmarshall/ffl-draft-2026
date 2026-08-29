module Mcp
  class LeaguesController < BaseController
    before_action :set_league, only: %i[show history]

    def index
      leagues = visible_leagues.order(:season, :name).preload(drafts: %i[draft_entries picks])
      render_json(leagues: leagues.map { |league| Mcp::LeagueData.new(league).summary })
    end

    def show
      render_json(Mcp::LeagueData.new(@league).detail)
    end

    def history
      render_json(Mcp::LeagueData.new(@league, season: params[:season]).history)
    end

    private

    def set_league
      @league = visible_leagues.includes(:drafts, :teams).find(params[:id])
    end
  end
end
