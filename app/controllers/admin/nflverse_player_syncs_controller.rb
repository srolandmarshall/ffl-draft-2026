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
        stats_season:,
        headshot_fetcher: ->(url) { client.fetch_headshot(url:) }
      ).call
      redirect_to admin_players_path,
        notice: "Loaded #{stats_season} actual stats for #{result.with_stats} players, marked #{result.rookies} rookies, and cached #{result.headshots_cached} headshots."
    rescue DataSources::HttpError, ActiveRecord::RecordInvalid => error
      redirect_to admin_players_path, alert: error.message
    end
  end
end
