module DataSources
  module Espn
    class HistoricalScoreSync
      Result = Data.define(:seasons, :scores)

      def initialize(league:, client:)
        @league = league
        @client = client
      end

      def call
        imports = seasons.to_h do |season|
          [ season, { players: client.fetch_players(year: season), scores: client.fetch_player_scores(year: season, league_id: league.espn_league_id) } ]
        end
        imported_scores = 0

        League.transaction do
          imports.each do |season, import|
            HistoricalPlayerImport.new(import.fetch(:players)).call
            imported_scores += LeaguePlayerScore.replace_for!(league:, season:, scores: import.fetch(:scores))
          end
        end

        Result.new(seasons: imports.size, scores: imported_scores)
      end

      private

      attr_reader :league, :client

      def seasons
        (league.espn_seasons.where("season < ?", league.season).pluck(:season) + [ league.season - 1 ]).uniq.sort
      end
    end
  end
end
