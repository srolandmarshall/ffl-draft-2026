require "test_helper"

class LeagueTest < ActiveSupport::TestCase
  test "requires a plausible season and roster size" do
    league = League.new(name: "Test", season: 1999, roster_size: 0)
    League::ROSTER_SLOT_ATTRIBUTES.each { |attribute| league.public_send("#{attribute}=", 0) }

    assert_not league.valid?
    assert_includes league.errors[:season], "must be greater than 2000"
    assert league.errors[:roster_size].any?
  end

  test "ESPN league ID is numeric and unique within a season" do
    leagues(:one).update!(espn_league_id: "123456")
    duplicate = League.new(name: "Duplicate", season: leagues(:one).season, roster_size: 16, espn_league_id: "123456")
    invalid = League.new(name: "Invalid", season: 2027, roster_size: 16, espn_league_id: "league-123")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:espn_league_id], "has already been taken"
    assert_not invalid.valid?
    assert_includes invalid.errors[:espn_league_id], "must contain only numbers"
  end
end
