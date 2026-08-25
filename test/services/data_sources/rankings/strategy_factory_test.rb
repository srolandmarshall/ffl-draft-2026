require "test_helper"

module DataSources
  module Rankings
    class StrategyFactoryTest < ActiveSupport::TestCase
      test "builds interchangeable ranking strategies" do
        league = leagues(:one)

        league_logs = StrategyFactory.build(source: "league_logs", league:, profile: "redraft-1qb-12t-ppr1")
        ffc = StrategyFactory.build(source: "fantasy_football_calculator", league:)

        assert_instance_of LeagueLogs, league_logs
        assert_instance_of FantasyFootballCalculator, ffc
      end

      test "rejects an unknown strategy" do
        assert_raises(ArgumentError) { StrategyFactory.build(source: "unknown", league: leagues(:one)) }
      end
    end
  end
end
