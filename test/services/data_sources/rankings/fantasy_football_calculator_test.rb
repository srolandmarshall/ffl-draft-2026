require "test_helper"

module DataSources
  module Rankings
    class FantasyFootballCalculatorTest < ActiveSupport::TestCase
      test "adapts ADP rows to the ranking strategy contract" do
        client = Object.new
        requested = nil
        client.define_singleton_method(:fetch_adp) do |scoring_format:, teams:, year:|
          requested = [ scoring_format, teams, year ]
          {
            "meta" => { "total_drafts" => 42 },
            "players" => [
              { "player_id" => 9_001, "name" => "Denver Defense", "position" => "DEF", "team" => "DEN", "adp" => 140.2 }
            ]
          }
        end

        snapshot = FantasyFootballCalculator.new(client:, scoring_format: "ppr", teams: 12, year: 2026).call
        entry = snapshot.entries.sole

        assert_equal [ "ppr", 12, 2026 ], requested
        assert_equal "fantasy_football_calculator", snapshot.source
        assert_equal Player::POSITIONS, snapshot.positions
        assert_equal "DST", entry.position
        assert_equal 140.2, entry.ranking
        assert_equal 42, snapshot.meta["total_drafts"]
      end
    end
  end
end
