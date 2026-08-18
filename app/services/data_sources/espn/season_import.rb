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
          teams: snapshot.teams.map(&:to_h),
          synced_at: Time.current
        )

        season.draft_picks.delete_all
        franchise_resolver = FranchiseResolver.new(league:)
        snapshot.draft_picks(player_catalog:).each do |pick|
          franchise = franchise_resolver.resolve(
            abbreviation: pick.team_abbreviation,
            name: pick.team_name,
            espn_team_id: pick.team_id,
            season: snapshot.season,
            owner_ids: pick.team_owner_ids
          )
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
    end
  end
end
