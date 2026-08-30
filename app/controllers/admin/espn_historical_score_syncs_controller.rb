module Admin
  class EspnHistoricalScoreSyncsController < BaseController
    def create
      league = League.find(params[:league_id])
      raise DataSources::HttpError, "Add an ESPN league ID first." if league.espn_league_id.blank?

      result = DataSources::Espn::HistoricalScoreSync.new(league:, client: espn_client).call
      redirect_to admin_league_path(league), notice: "Imported #{result.scores} player scores across #{result.seasons} historical seasons."
    rescue DataSources::HttpError, ActiveRecord::RecordInvalid => error
      redirect_to admin_league_path(params[:league_id]), alert: error.message
    end
  end
end
