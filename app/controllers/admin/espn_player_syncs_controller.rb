module Admin
  class EspnPlayerSyncsController < BaseController
    def create
      year = League.maximum(:season) || Date.current.year
      league = League.where(season: year).where.not(espn_league_id: nil).first
      rows = espn_client.fetch_players(year:)
      rows = merge_private_updates(rows, year:, league:) if league && espn_connected?
      result = DataSources::Espn::PlayerIdSync.new(rows).call
      redirect_to admin_players_path, notice: "ESPN player pool synced: #{result.matched} existing players updated and #{result.created} missing players added."
    rescue DataSources::HttpError, ActiveRecord::RecordInvalid => error
      redirect_to admin_players_path, alert: error.message
    end

    private

    def merge_private_updates(rows, year:, league:)
      updates = espn_client.fetch_player_updates(year:, league_id: league.espn_league_id).index_by { |row| row.fetch("id").to_i }
      rows.map { |row| row.merge(updates.fetch(row.fetch("id").to_i, {})) }
    end
  end
end
