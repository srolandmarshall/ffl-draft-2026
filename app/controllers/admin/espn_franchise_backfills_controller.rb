module Admin
  class EspnFranchiseBackfillsController < BaseController
    before_action :set_league

    def create
      result = DataSources::Espn::FranchiseBackfill.new(league: @league).call
      redirect_to admin_league_path(@league), notice: "Repaired #{result.team_seasons} ESPN team seasons across #{result.franchises} franchises and reassigned #{result.picks} draft picks."
    end

    private

    def set_league
      @league = League.find(params[:league_id])
    end
  end
end
