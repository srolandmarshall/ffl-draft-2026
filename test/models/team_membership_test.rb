require "test_helper"

class TeamMembershipTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert team_memberships(:one).valid?
  end

  test "requires a team and a user" do
    membership = TeamMembership.new
    assert_not membership.valid?
    assert_includes membership.errors[:team], "must exist"
    assert_includes membership.errors[:user], "must exist"
  end

  test "does not allow the same user to join the same team twice" do
    duplicate = TeamMembership.new(team: teams(:one), user: users(:member))
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "allows the same user to belong to teams in different leagues" do
    other_membership = TeamMembership.new(team: teams(:two), user: users(:member))
    assert other_membership.valid?
  end

  test "allows different users on the same team" do
    other_user = User.create!(email: "second-owner@example.com")
    other_membership = TeamMembership.new(team: teams(:one), user: other_user)
    assert other_membership.valid?
  end
end
