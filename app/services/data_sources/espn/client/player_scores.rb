module DataSources
  module Espn
    class Client
      class PlayerScores
        def initialize(payload, year:)
          @payload = payload
          @year = Integer(year)
        end

        def players
          payload.fetch("players", []).map { |entry| entry.fetch("player", entry) }
        end

        def scores
          result = players.filter_map do |player|
            stat = Array(player["stats"]).find { |candidate| season_total?(candidate) }
            next unless stat&.key?("appliedTotal")

            PlayerScore.new(
              espn_id: player.fetch("id").to_i,
              points: BigDecimal(stat.fetch("appliedTotal").to_s),
              stats: stat.fetch("stats", {})
            )
          end
          raise HttpError, "ESPN returned no league-scored player totals for #{year}" if result.empty?

          result
        end

        private

        attr_reader :payload, :year

        def season_total?(stat)
          stat["seasonId"].to_i == year && stat["scoringPeriodId"].to_i.zero? &&
            stat["statSourceId"].to_i.zero? && stat["statSplitTypeId"].to_i.zero?
        end
      end
    end
  end
end
