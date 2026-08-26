class NflverseHeadshotSyncJob < ApplicationJob
  queue_as :default

  limits_concurrency to: 1, key: ->(*) { "nflverse-headshot-sync" }, duration: 1.hour

  def perform(current_season, stats_season)
    DataSources::Nflverse::PlayerDataSync.new(
      player_rows: client.fetch_players,
      stat_rows: client.fetch_actual_stats(year: stats_season),
      current_season:,
      stats_season:,
      headshot_fetcher: ->(url) { client.fetch_headshot(url:) }
    ).call
  end

  private

  def client
    @client ||= DataSources::Nflverse::Client.new
  end
end
