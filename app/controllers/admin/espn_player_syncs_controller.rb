module Admin
  class EspnPlayerSyncsController < BaseController
    def create
      year = League.maximum(:season) || Date.current.year
      rows = DataSources::Espn::Client.new.fetch_players(year:)
      result = DataSources::Espn::PlayerIdSync.new(rows).call
      redirect_to admin_players_path, notice: "Matched #{result.matched} ESPN player IDs; #{result.unmatched} ESPN players had no local match."
    rescue DataSources::HttpError, ActiveRecord::RecordInvalid => error
      redirect_to admin_players_path, alert: error.message
    end
  end
end
