module DataSources
  module Espn
    class LeagueSync
      Result = Data.define(
        :teams_matched, :teams_created, :seasons_imported, :seasons_skipped,
        :standings_imported, :matchups_imported, :player_scores_imported
      )

      def initialize(league:, client:)
        @league = league
        @client = client
      end

      def call
        current = client.fetch_league_snapshot(year: league.season, league_id: league.espn_league_id)
        snapshots, skipped = history_snapshots(current)
        player_rows = snapshots.to_h do |snapshot|
          [ snapshot.season, client.fetch_players(year: snapshot.season) ]
        end
        catalogs = player_rows.transform_values { |rows| PlayerCatalog.new(rows) }
        player_updates = client.fetch_player_updates(year: league.season, league_id: league.espn_league_id)
        historical_seasons = (snapshots.map(&:season) + [ league.season - 1 ]).uniq.select { |season| season < league.season }
        player_scores = historical_seasons.to_h do |season|
          [ season, client.fetch_player_scores(year: season, league_id: league.espn_league_id) ]
        end

        team_result = nil
        standings_imported = 0
        matchups_imported = 0
        player_scores_imported = nil
        League.transaction do
          LeagueSettingsImport.new(league:, settings: current.settings).call
          PlayerIdSync.new(player_updates).call
          snapshots.each do |snapshot|
            HistoricalPlayerImport.new(player_rows.fetch(snapshot.season)).call if snapshot.season < league.season
            imported = SeasonImport.new(league:, snapshot:, player_catalog: catalogs.fetch(snapshot.season)).call
            standings_imported += imported.team_seasons.size
            matchups_imported += imported.matchups.size
          end
          team_result = TeamImport.new(league:, teams: current.teams).call
          player_scores_imported = player_scores.sum do |season, scores|
            LeaguePlayerScore.replace_for!(league:, season:, scores:)
          end
        end

        Result.new(
          teams_matched: team_result.matched,
          teams_created: team_result.created,
          seasons_imported: snapshots.size,
          seasons_skipped: skipped,
          standings_imported:,
          matchups_imported:,
          player_scores_imported:
        )
      end

      private

      attr_reader :league, :client

      def history_snapshots(current)
        snapshots = []
        skipped = []
        current.previous_seasons.sort.each do |season|
          snapshots << client.fetch_league_snapshot(year: season, league_id: league.espn_league_id)
        rescue HttpError
          skipped << season
        end
        snapshots << current
        [ snapshots.uniq(&:season), skipped ]
      end
    end
  end
end
