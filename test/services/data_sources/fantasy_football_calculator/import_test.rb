require "test_helper"

module DataSources
  module FantasyFootballCalculator
    class ImportTest < ActiveSupport::TestCase
      test "adds ADP metadata and updates an existing natural-key player" do
        payload = {
          "meta" => { "total_drafts" => 42 },
          "players" => [
            {
              "player_id" => 9_001, "name" => players(:one).name, "position" => "QB", "team" => "ATL",
              "adp" => 22.4, "adp_formatted" => "2.10", "times_drafted" => 88, "stdev" => 3.2, "bye" => 8
            },
            {
              "player_id" => 9_002, "name" => "Denver Defense", "position" => "DEF", "team" => "DEN",
              "adp" => 140.0, "adp_formatted" => "12.08", "times_drafted" => 20, "stdev" => 8.0, "bye" => 10
            }
          ]
        }

        result = assert_difference("Player.count", 1) { Import.new(payload).call }

        assert_equal 1, result.created
        assert_equal 1, result.updated
        assert_equal 22.4, players(:one).reload.adp
        assert_equal "DST", Player.find_by!(ffc_id: 9_002).position
      end
    end
  end
end
