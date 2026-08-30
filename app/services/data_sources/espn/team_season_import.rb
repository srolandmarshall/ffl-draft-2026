module DataSources
  module Espn
    class TeamSeasonImport
      def initialize(league:, season:, identities:)
        @league = league
        @season = season
        @identities = identities
      end

      def call
        stale_rows.update_all(espn_franchise_id: nil)
        resolver = FranchiseResolver.new(league:)
        identities.each do |identity|
          espn_team_id = attribute(identity, :id).to_i
          team_name = attribute(identity, :name).presence || "ESPN Team #{espn_team_id}"
          team_abbreviation = attribute(identity, :abbreviation).presence || "T#{espn_team_id}"
          owner_ids = Array(attribute(identity, :owner_ids))
          franchise = resolver.resolve(
            abbreviation: team_abbreviation,
            name: team_name,
            espn_team_id:,
            season:,
            owner_ids:
          )
          season.team_seasons.find_or_initialize_by(espn_team_id:).update!(
            espn_franchise: franchise,
            team_name:,
            team_abbreviation:,
            owner_ids:,
            owner_names: Array(attribute(identity, :owner_names)),
            espn_final_rank: positive_integer(attribute(identity, :espn_final_rank) || attribute(identity, :final_rank)),
            division_id: attribute(identity, :division_id)
          )
        end
        season.team_seasons.where(espn_team_id: team_ids)
      end

      def remove_stale!
        stale_rows.destroy_all
      end

      private

      attr_reader :league, :season, :identities

      def stale_rows
        season.team_seasons.where.not(espn_team_id: team_ids)
      end

      def team_ids
        @team_ids ||= identities.map { |identity| attribute(identity, :id).to_i }
      end

      def attribute(identity, name)
        return identity.public_send(name) if identity.respond_to?(name)
        return unless identity.respond_to?(:[])

        identity[name.to_s] || identity[name]
      end

      def positive_integer(value)
        value.to_i if value.to_i.positive?
      end
    end
  end
end
