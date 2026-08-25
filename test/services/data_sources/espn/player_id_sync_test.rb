require "test_helper"

module DataSources
  module Espn
    class PlayerIdSyncTest < ActiveSupport::TestCase
      test "matches existing ESPN identities and adds missing eligible players" do
        defense = Player.create!(name: "Atlanta Defense", position: "DST", pro_team: "ATL")
        kicker = Player.create!(name: "Eddy Piñeiro", position: "K", pro_team: "SF")
        rows = [
          { "id" => 77_001, "fullName" => "#{players(:one).name} Jr.", "defaultPositionId" => 1, "proTeamId" => 2, "injuryStatus" => "DOUBTFUL", "injured" => true },
          { "id" => 77_002, "fullName" => "Atlanta Falcons", "defaultPositionId" => 16, "proTeamId" => 1 },
          { "id" => 77_004, "fullName" => "Eddy Pineiro", "defaultPositionId" => 5, "proTeamId" => 25 },
          { "id" => 77_003, "fullName" => "No Local Match", "defaultPositionId" => 3, "proTeamId" => 2 }
        ]

        assert_difference("Player.count", 1) do
          result = PlayerIdSync.new(rows).call
          assert_equal 3, result.matched
          assert_equal 1, result.created
        end

        assert_equal 77_001, players(:one).reload.espn_id
        assert_equal "DOUBTFUL", players(:one).injury_status
        assert players(:one).injury_updated_at.present?
        assert_equal 77_002, defense.reload.espn_id
        assert_equal 77_004, kicker.reload.espn_id
        assert_equal 77_003, Player.find_by!(name: "No Local Match").espn_id
      end
    end
  end
end
