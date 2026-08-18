module DataSources
  module Espn
    class FranchiseBackfill
      def initialize(league:)
        @league = league
      end

      def call
        resolver = FranchiseResolver.new(league:)
        picks.each do |pick|
          franchise = resolver.resolve(
            abbreviation: pick.team_abbreviation,
            name: pick.team_name,
            espn_team_id: pick.espn_team_id,
            season: pick.espn_season.season,
            owner_ids: owner_ids_for(pick)
          )
          pick.update!(espn_franchise: franchise)
        end
      end

      private

      attr_reader :league

      def picks
        EspnDraftPick.joins(:espn_season).where(espn_seasons: { league_id: league.id }).order("espn_seasons.season", :overall_number)
      end

      def owner_ids_for(pick)
        team = pick.espn_season.teams.find { |identity| identity["id"].to_i == pick.espn_team_id }
        Array(team&.fetch("owner_ids", nil))
      end
    end
  end
end
