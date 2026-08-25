require "test_helper"

class DraftTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @draft = drafts(:one)
    @second_team = @draft.league.teams.create!(name: "Green Giants", owner_name: "Greer", abbreviation: "GRN")
    @draft.draft_entries.create!(team: @second_team, position: 2)
  end

  test "calculates snake order" do
    assert_equal teams(:one), @draft.current_team
    assert_equal 0, @draft.picks_until_team(teams(:one))
    assert_equal 1, @draft.picks_until_team(@second_team)

    make_pick(teams(:one), players(:one))
    assert_equal @second_team, @draft.current_team
    assert_equal 2, @draft.picks_until_team(teams(:one))

    make_pick(@second_team, players(:two))
    assert_equal @second_team, @draft.current_team, "round two reverses direction"
  end

  test "enqueues an automatic start when a future time is scheduled" do
    draft = drafts(:two)
    scheduled_at = 2.hours.from_now

    assert_enqueued_with(job: StartScheduledDraftJob, args: [ draft ], at: scheduled_at) do
      draft.update!(scheduled_start_at: scheduled_at)
    end
  end

  test "rejects a newly scheduled start in the past" do
    draft = drafts(:two)

    refute draft.update(scheduled_start_at: 1.minute.ago)
    assert_predicate draft.errors[:scheduled_start_at], :present?
  end

  private

  def make_pick(team, player)
    Drafts::MakePick.new(draft: @draft, team:, player:).call
  end
end
