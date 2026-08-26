module Admin
  class NflversePlayerSyncsController < BaseController
    def create
      current_season = League.maximum(:season) || Date.current.year
      stats_season = current_season - 1
      client = DataSources::Nflverse::Client.new
      result = DataSources::Nflverse::PlayerDataSync.new(
        player_rows: client.fetch_players,
        stat_rows: client.fetch_actual_stats(year: stats_season),
        current_season:,
        stats_season:
      ).call
      NflverseHeadshotSyncJob.perform_later(current_season, stats_season)
      redirect_to admin_players_path,
        notice: "Loaded #{stats_season} actual stats for #{result.with_stats} players and marked #{result.rookies} rookies. Headshots will continue caching in the background."
    rescue DataSources::HttpError, ActiveRecord::RecordInvalid => error
      redirect_to admin_players_path, alert: error.message
    end
  end
end
