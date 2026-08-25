module DataSources
  module Espn
    class LeagueSync
      Result = Data.define(:teams_matched, :teams_created, :seasons_imported, :seasons_skipped, :player_scores_imported)

      def initialize(league:, client:)
        @league = league
        @client = client
      end

      def call
        current = client.fetch_league_snapshot(year: league.season, league_id: league.espn_league_id)
        snapshots, skipped = history_snapshots(current)
        catalogs = snapshots.to_h do |snapshot|
          [ snapshot.season, PlayerCatalog.new(client.fetch_players(year: snapshot.season)) ]
        end
        player_updates = client.fetch_player_updates(year: league.season, league_id: league.espn_league_id)
        score_season = league.season - 1
        player_scores = client.fetch_player_scores(year: score_season, league_id: league.espn_league_id)

        team_result = nil
        player_scores_imported = nil
        League.transaction do
          LeagueSettingsImport.new(league:, settings: current.settings).call
          team_result = TeamImport.new(league:, teams: current.teams).call
          PlayerIdSync.new(player_updates).call
          snapshots.each do |snapshot|
            SeasonImport.new(league:, snapshot:, player_catalog: catalogs.fetch(snapshot.season)).call
          end
          player_scores_imported = LeaguePlayerScore.replace_for!(
            league:, season: score_season, scores: player_scores
          )
        end

        Result.new(
          teams_matched: team_result.matched,
          teams_created: team_result.created,
          seasons_imported: snapshots.size,
          seasons_skipped: skipped,
          player_scores_imported:
        )
      end

      private

      attr_reader :league, :client

      def history_snapshots(current)
        snapshots = [ current ]
        skipped = []
        current.previous_seasons.sort.reverse.each do |season|
          snapshots << client.fetch_league_snapshot(year: season, league_id: league.espn_league_id)
        rescue HttpError
          skipped << season
        end
        [ snapshots.uniq(&:season), skipped ]
      end
    end
  end
end
