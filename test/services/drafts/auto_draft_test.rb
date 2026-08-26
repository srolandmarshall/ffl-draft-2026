require "test_helper"

module Drafts
  class AutoDraftTest < ActiveSupport::TestCase
    # Returns queued values from `rand` in order, so pick outcomes are
    # reproducible instead of depending on Ruby's PRNG internals.
    class FakeRandom
      def initialize(values)
        @values = values.dup
      end

      def rand
        @values.shift or raise "FakeRandom ran out of queued values"
      end
    end

    # Always favors the top-ranked candidate in the pool (roll lands in the first weight bucket).
    def top_of_pool_random
      FakeRandom.new(Array.new(200, 0.0))
    end

    setup do
      @league = leagues(:one)
      @team_a = teams(:one)
      @team_b = @league.teams.create!(name: "Team B", owner_name: "Bailey", abbreviation: "TMB")

      @draft = @league.drafts.create!(
        name: "Auto Draft Test",
        public_id: "auto-draft-test",
        status: :setup,
        rounds: 3,
        qb_slots: 1, rb_slots: 1, wr_slots: 1, te_slots: 0, flex_slots: 0, k_slots: 0, dst_slots: 0, bench_slots: 0
      )
      @draft.draft_entries.create!(team: @team_a, position: 1)
      @draft.draft_entries.create!(team: @team_b, position: 2)

      @qb1 = create_player("QB One", "QB", ranking: 1)
      @qb2 = create_player("QB Two", "QB", ranking: 2)
      @qb3 = create_player("QB Three", "QB", ranking: 3)
      @rb1 = create_player("RB One", "RB", ranking: 4)
      @rb2 = create_player("RB Two", "RB", ranking: 5)
      @wr1 = create_player("WR One", "WR", ranking: 6)
      @wr2 = create_player("WR Two", "WR", ranking: 7)
    end

    test "starts a setup draft and fills every remaining pick" do
      AutoDraft.new(@draft, random: top_of_pool_random).call

      assert @draft.reload.complete?
      assert_equal @draft.total_picks, @draft.picks.count
    end

    test "respects each team's position limits instead of stacking the top-ranked position" do
      AutoDraft.new(@draft, random: top_of_pool_random).call

      [ @team_a, @team_b ].each do |team|
        positions = @draft.picks.where(team:).includes(:player).map { |pick| pick.player.position }
        assert_equal %w[QB RB WR].sort, positions.sort
      end
    end

    test "takes the top-ranked player for the need when the random roll favors it" do
      AutoDraft.new(@draft, random: top_of_pool_random).call

      assert @draft.picks.exists?(player: @qb1)
      assert @draft.picks.exists?(player: @qb2)
      assert_not @draft.picks.exists?(player: @qb3)
    end

    test "gives every team its fair share of the remaining picks" do
      AutoDraft.new(@draft, random: top_of_pool_random).call

      counts = @draft.picks.group(:team_id).count
      assert_equal [ 3, 3 ], counts.values.sort
    end

    test "stops gracefully when the available player pool runs out early" do
      Player.where.not(id: [ @qb1, @qb2, @rb1, @rb2 ].map(&:id)).find_each(&:destroy!)

      AutoDraft.new(@draft, random: top_of_pool_random).call

      assert_not @draft.reload.complete?
      assert_equal 4, @draft.picks.count
    end

    test "can reach for a lower-ranked player within the pool for realism" do
      random = FakeRandom.new([ 0.99 ] + Array.new(200, 0.0))

      AutoDraft.new(@draft, random:).call

      assert @draft.picks.exists?(player: @qb3), "expected the first pick to reach for the third-ranked QB"
    end

    test "never reaches outside the top-ranked pool" do
      solo_team = @league.teams.create!(name: "Solo Team", owner_name: "Sam", abbreviation: "SLO")
      solo_draft = @league.drafts.create!(
        name: "Solo Draft", public_id: "auto-draft-solo", status: :setup, rounds: 1,
        qb_slots: 1, rb_slots: 0, wr_slots: 0, te_slots: 0, flex_slots: 0, k_slots: 0, dst_slots: 0, bench_slots: 0
      )
      solo_draft.draft_entries.create!(team: solo_team, position: 1)

      create_player("Solo QB One", "QB", ranking: 1)
      create_player("Solo QB Two", "QB", ranking: 2)
      create_player("Solo QB Three", "QB", ranking: 3)
      qb_worst = create_player("Solo QB Worst", "QB", ranking: 4)

      AutoDraft.new(solo_draft, random: FakeRandom.new(Array.new(200, 0.999))).call

      assert_not solo_draft.picks.exists?(player: qb_worst)
    end

    private

    def create_player(name, position, ranking:)
      Player.create!(name:, position:, pro_team: "FA", active: true, ranking:)
    end
  end
end
