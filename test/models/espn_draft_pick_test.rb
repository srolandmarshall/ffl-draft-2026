require "test_helper"

class EspnDraftPickTest < ActiveSupport::TestCase
  test "accepts ESPN's negative team defense player IDs" do
    pick = espn_draft_picks(:one)
    pick.espn_player_id = -1_6001
    pick.position = "DST"

    assert_predicate pick, :valid?
  end

  test "rejects ESPN's undrafted player placeholder" do
    pick = espn_draft_picks(:one)
    pick.espn_player_id = -1

    assert_not_predicate pick, :valid?
    assert_includes pick.errors[:espn_player_id], "is an undrafted ESPN placeholder"
  end
end
