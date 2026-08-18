require "test_helper"

module DataSources
  module Espn
    class PlayerIdSyncTest < ActiveSupport::TestCase
      test "matches ESPN identities without creating another player pool" do
        defense = Player.create!(name: "Atlanta Defense", position: "DST", pro_team: "ATL")
        kicker = Player.create!(name: "Eddy Piñeiro", position: "K", pro_team: "SF")
        rows = [
          { "id" => 77_001, "fullName" => "#{players(:one).name} Jr.", "defaultPositionId" => 1, "proTeamId" => 2 },
          { "id" => 77_002, "fullName" => "Atlanta Falcons", "defaultPositionId" => 16, "proTeamId" => 1 },
          { "id" => 77_004, "fullName" => "Eddy Pineiro", "defaultPositionId" => 5, "proTeamId" => 25 },
          { "id" => 77_003, "fullName" => "No Local Match", "defaultPositionId" => 3, "proTeamId" => 2 }
        ]

        assert_no_difference("Player.count") do
          result = PlayerIdSync.new(rows).call
          assert_equal 3, result.matched
          assert_equal 1, result.unmatched
        end

        assert_equal 77_001, players(:one).reload.espn_id
        assert_equal 77_002, defense.reload.espn_id
        assert_equal 77_004, kicker.reload.espn_id
      end
    end
  end
end
