module DataSources
  module Nflverse
    class PlayerDataSync
      INTEGER_STATS = %w[
        games completions attempts passing_yards passing_tds passing_interceptions
        carries rushing_yards rushing_tds receptions targets receiving_yards receiving_tds
        fg_made fg_att pat_made pat_att
      ].freeze
      DECIMAL_STATS = %w[fantasy_points].freeze
      Result = Data.define(:updated, :with_stats, :rookies, :unmatched, :headshots_cached, :headshots_failed)

      def initialize(player_rows:, stat_rows:, current_season:, stats_season:, headshot_fetcher: nil)
        @player_rows = player_rows
        @stat_rows = stat_rows
        @current_season = current_season.to_i
        @stats_season = stats_season.to_i
        @headshot_fetcher = headshot_fetcher
      end

      def call
        updated = 0
        with_stats = 0
        rookies = 0
        unmatched = 0
        headshots_cached = 0
        headshots_failed = 0
        headshots_to_cache = []
        metadata_by_espn_id = player_rows.filter_map do |row|
          espn_id = integer(row["espn_id"])
          [ espn_id, row ] if espn_id
        end.to_h
        stats_by_player_id = stat_rows
          .select { |row| integer(row["season"]) == stats_season && row["season_type"] == "REG" }
          .index_by { |row| row["player_id"] }

        Player.where.not(espn_id: nil).find_each do |player|
          metadata = metadata_by_espn_id[player.espn_id]
          unless metadata
            unmatched += 1
            next
          end

          rookie = integer(metadata["rookie_season"]) == current_season
          stats = stats_by_player_id[metadata["gsis_id"]]
          headshot_url = metadata["headshot"].presence
          headshot_changed = player.headshot_url != headshot_url
          player.update!(
            rookie:,
            headshot_url:,
            actual_stats: stats ? extract_stats(stats) : nil,
            stats_season: stats ? stats_season : nil
          )
          if headshot_fetcher && headshot_url && (!player.headshot.attached? || headshot_changed)
            headshots_to_cache << [ player, headshot_url ]
          end
          updated += 1
          with_stats += 1 if stats
          rookies += 1 if rookie
        end

        headshots_to_cache.each do |player, headshot_url|
          if cache_headshot(player, headshot_url)
            headshots_cached += 1
          else
            headshots_failed += 1
          end
        end

        Result.new(updated:, with_stats:, rookies:, unmatched:, headshots_cached:, headshots_failed:)
      end

      private

      attr_reader :player_rows, :stat_rows, :current_season, :stats_season, :headshot_fetcher

      def cache_headshot(player, url)
        download = headshot_fetcher.call(url)
        player.headshot.attach(
          io: download.io,
          filename: "player-#{player.id}.#{download.extension}",
          content_type: download.content_type
        )
        true
      rescue StandardError => error
        Rails.logger.warn("Unable to cache headshot for player #{player.id}: #{error.class}: #{error.message}")
        false
      end

      def extract_stats(row)
        INTEGER_STATS.to_h { |name| [ name, integer(row[name]).to_i ] }
          .merge(DECIMAL_STATS.to_h { |name| [ name, decimal(row[name]).to_f ] })
      end

      def integer(value)
        return if value.blank?

        value.to_f.to_i
      end

      def decimal(value)
        return if value.blank?

        BigDecimal(value)
      end
    end
  end
end
