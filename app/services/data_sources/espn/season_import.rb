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

        import_team_seasons(season)
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

      def import_team_seasons(season)
        team_ids = snapshot.teams.map { |identity| identity_attribute(identity, :id).to_i }
        season.team_seasons.where.not(espn_team_id: team_ids).destroy_all
        resolver = FranchiseResolver.new(league:)
        snapshot.teams.each do |identity|
          espn_team_id = identity_attribute(identity, :id).to_i
          team_name = identity_attribute(identity, :name).presence || "ESPN Team #{espn_team_id}"
          team_abbreviation = identity_attribute(identity, :abbreviation).presence || "T#{espn_team_id}"
          owner_ids = Array(identity_attribute(identity, :owner_ids))
          row = season.team_seasons.find_or_initialize_by(espn_team_id:)
          franchise = resolver.resolve(
            abbreviation: team_abbreviation,
            name: team_name,
            espn_team_id:,
            season:,
            owner_ids:
          )
          row.update!(
            espn_franchise: franchise,
            team_name:,
            team_abbreviation:,
            owner_ids:,
            owner_names: Array(identity_attribute(identity, :owner_names)),
            espn_final_rank: positive_integer(identity_attribute(identity, :final_rank))
          )
        end
      end

      def identity_attribute(identity, name)
        return identity.public_send(name) if identity.respond_to?(name)

        identity[name.to_s] || identity[name]
      end

      def positive_integer(value)
        value.to_i if value.to_i.positive?
      end
    end
  end
end
