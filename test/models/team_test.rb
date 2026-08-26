require "test_helper"

class TeamTest < ActiveSupport::TestCase
  test "active scope excludes archived teams" do
    archived = teams(:one)
    archived.update!(archived: true)

    assert_includes Team.active, teams(:two)
    assert_not_includes Team.active, archived
  end

  test "archived scope only returns archived teams" do
    teams(:one).update!(archived: true)

    assert_equal [ teams(:one) ], Team.archived.to_a
  end

  test "new teams default to not archived" do
    assert_not teams(:one).archived?
  end
end
