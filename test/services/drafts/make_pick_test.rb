require "test_helper"

module Drafts
  class MakePickTest < ActiveSupport::TestCase
    setup do
      @draft = drafts(:one)
      @team = teams(:one)
      @player = players(:one)
    end

    test "records the expected team, round, and overall number" do
      @draft.update!(started_at: 75.seconds.ago, pick_timer_paused_seconds: 15)
      pick = MakePick.new(draft: @draft, team: @team, player: @player).call

      assert_equal 1, pick.round
      assert_equal 1, pick.overall_number
      assert_equal @team, pick.team
      assert_in_delta 60, pick.elapsed_seconds, 1
      assert_equal 0, @draft.reload.pick_timer_paused_seconds
    end

    test "rejects a pick from a team that is not on the clock" do
      other_team = @draft.league.teams.create!(name: "Wrong Team", owner_name: "Wren", abbreviation: "WRG")

      error = assert_raises(MakePick::InvalidPick) do
        MakePick.new(draft: @draft, team: other_team, player: @player).call
      end

      assert_match(/not .* turn/, error.message)
      assert_equal 0, Pick.count
    end

    test "rejects a duplicate player" do
      MakePick.new(draft: @draft, team: @team, player: @player).call

      error = assert_raises(MakePick::InvalidPick) do
        MakePick.new(draft: @draft, team: @team, player: @player).call
      end

      assert_match(/already been drafted/, error.message)
    end

    test "does not allow picks before the draft starts" do
      draft = drafts(:two)

      assert_raises(MakePick::InvalidPick) do
        MakePick.new(draft:, team: teams(:two), player: @player).call
      end
    end
  end
end
