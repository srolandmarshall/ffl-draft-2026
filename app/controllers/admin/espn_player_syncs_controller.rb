module Admin
  class EspnPlayerSyncsController < BaseController
    def create
      year = League.maximum(:season) || Date.current.year
      league = League.where(season: year).where.not(espn_league_id: nil).first
      rows = if league
        espn_client.fetch_player_updates(year:, league_id: league.espn_league_id)
      else
        espn_client.fetch_players(year:)
      end
      result = DataSources::Espn::PlayerIdSync.new(rows).call
      redirect_to admin_players_path, notice: "Matched #{result.matched} ESPN player IDs and refreshed injury statuses; #{result.unmatched} ESPN players had no local match."
    rescue DataSources::HttpError, ActiveRecord::RecordInvalid => error
      redirect_to admin_players_path, alert: error.message
    end
  end
end
