module DataSources
  module Rankings
    class StrategyFactory
      DEFAULT_SOURCE = "league_logs".freeze

      def self.build(source: ENV.fetch("PLAYER_RANKINGS_SOURCE", DEFAULT_SOURCE), league:, profile: nil)
        case source
        when LeagueLogs::SOURCE
          LeagueLogs.new(profile: profile.presence || LeagueLogs.default_profile(league))
        when FantasyFootballCalculator::SOURCE
          FantasyFootballCalculator.new(
            scoring_format: scoring_format(league),
            teams: (league&.teams&.count || 12).clamp(8, 14),
            year: league&.season || Date.current.year
          )
        else
          raise ArgumentError, "Unknown player rankings source"
        end
      end

      def self.scoring_format(league)
        return "2-qb" if league&.qb_slots.to_i >= 2
        return "ppr" if league.nil? || league.ppr.to_f >= 0.75
        return "half-ppr" if league.ppr.to_f >= 0.25

        "standard"
      end
      private_class_method :scoring_format
    end
  end
end
