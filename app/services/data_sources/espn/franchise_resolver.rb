module DataSources
  module Espn
    class FranchiseResolver
      def initialize(league:)
        @league = league
      end

      def resolve(abbreviation:, name:, espn_team_id:, season:, owner_ids: [])
        owner_ids = Array(owner_ids).compact.uniq
        franchise = league.espn_franchises.to_a.find { |candidate| candidate.matches_owner_ids?(owner_ids) }
        franchise ||= league.espn_franchises.to_a.find { |candidate| candidate.matches_alias?(abbreviation) }
        franchise ||= league.espn_franchises.find_by(key: key_for(abbreviation, espn_team_id, season))
        team = league.teams.find { |candidate| candidate.abbreviation.casecmp?(abbreviation.to_s) }
        franchise ||= league.espn_franchises.build(key: key_for(abbreviation, espn_team_id, season))
        franchise.team ||= team
        franchise.name = franchise.team&.name || name
        franchise.aliases = (franchise.aliases + [ abbreviation ]).compact.uniq
        franchise.owner_ids = (franchise.owner_ids + owner_ids).uniq
        franchise.save!
        franchise
      end

      private

      attr_reader :league

      def key_for(abbreviation, espn_team_id, season)
        normalized = ActiveSupport::Inflector.transliterate(abbreviation.to_s).upcase.gsub(/[^A-Z0-9]/, "")
        normalized.presence || "ESPN-#{espn_team_id}-#{season}"
      end
    end
  end
end
