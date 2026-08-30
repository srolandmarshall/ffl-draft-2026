module DataSources
  module Espn
    class SeasonImport
      def initialize(league:, snapshot:, player_catalog:)
        @league = league
        @snapshot = snapshot
        @player_catalog = player_catalog
      end

      def call
        season = league.espn_seasons.find_or_initialize_by(season: snapshot.season)
        season.update!(
          name: snapshot.name,
          team_count: snapshot.teams.size,
          settings: snapshot.settings.raw_snapshot,
          teams: snapshot.teams.map { |identity| archived_identity(identity) },
          synced_at: Time.current
        )

        team_season_import = TeamSeasonImport.new(league:, season:, identities: snapshot.teams)
        team_season_import.call
        matchups = snapshot.respond_to?(:matchups) ? Array(snapshot.matchups) : []
        MatchupImport.new(season:, matchups:).call
        team_season_import.remove_stale!
        StandingsImport.new(season:, identities: snapshot.teams).call
        Leagues::PlayoffFinishCalculator.new(season:).call
        season.draft_picks.delete_all
        snapshot.draft_picks(player_catalog:).each do |pick|
          franchise = season.team_seasons.find_by!(espn_team_id: pick.team_id).espn_franchise
          season.draft_picks.create!(
            espn_franchise: franchise,
            overall_number: pick.overall_number,
            round: pick.round,
            round_pick: pick.round_pick,
            espn_team_id: pick.team_id,
            team_name: pick.team_name,
            team_abbreviation: pick.team_abbreviation,
            espn_player_id: pick.player_id,
            player_name: pick.player_name,
            position: pick.position
          )
        end

        season
      end

      private

      attr_reader :league, :snapshot, :player_catalog

      def archived_identity(identity)
        identity.to_h.transform_values { |value| value.is_a?(Data) ? value.to_h : value }
      end
    end
  end
end
