module Mcp
  class LeaguesController < BaseController
    before_action :set_league, only: %i[show history]

    def index
      render_json(leagues: visible_leagues.order(:season, :name).map { |league| Mcp::LeagueData.new(league).summary })
    end

    def show
      render_json(Mcp::LeagueData.new(@league).detail)
    end

    def history
      render_json(Mcp::LeagueData.new(@league).history)
    end

    private

    def set_league
      @league = visible_leagues.includes(:drafts, :teams).find(params[:id])
    end
  end
end
