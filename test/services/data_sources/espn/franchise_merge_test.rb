require "test_helper"

module DataSources
  module Espn
    class FranchiseMergeTest < ActiveSupport::TestCase
      setup do
        @league = League.create!(name: "Merge League", season: 2026)
        @target = @league.espn_franchises.create!(key: "TARGET", name: "Target Franchise", aliases: [ "TGT" ], owner_ids: [ 1 ])
        @source = @league.espn_franchises.create!(key: "SOURCE", name: "Source Franchise", aliases: [ "SRC" ], owner_ids: [ 2 ])
        @season = @league.espn_seasons.create!(season: 2025, name: "2025", team_count: 1, settings: {}, teams: [], synced_at: Time.current)
        @pick = @season.draft_picks.create!(
          espn_franchise: @source, overall_number: 1, round: 1, round_pick: 1, espn_team_id: 9,
          team_name: "Source Team", team_abbreviation: "SRC", espn_player_id: 100, player_name: "Some Player", position: "RB"
        )
      end

      test "unions aliases and owner ids, reassigns draft picks, and destroys the sources" do
        result = FranchiseMerge.new(target: @target, sources: [ @source ]).call

        assert_equal @target, result
        assert_equal %w[TGT SRC], result.aliases
        assert_equal [ 1, 2 ], result.owner_ids
        assert_equal @target.id, @pick.reload.espn_franchise_id
        assert_not EspnFranchise.exists?(@source.id)
      end

      test "keeps the target name when no override name is given" do
        FranchiseMerge.new(target: @target, sources: [ @source ]).call

        assert_equal "Target Franchise", @target.reload.name
      end

      test "renames the target when an override name is given" do
        FranchiseMerge.new(target: @target, sources: [ @source ], name: "Merged Franchise").call

        assert_equal "Merged Franchise", @target.reload.name
      end

      test "merges multiple sources into a single target in one call" do
        third = @league.espn_franchises.create!(key: "THIRD", name: "Third Franchise", aliases: [ "THD" ], owner_ids: [ 3 ])

        result = FranchiseMerge.new(target: @target, sources: [ @source, third ]).call

        assert_equal %w[TGT SRC THD], result.aliases
        assert_equal [ 1, 2, 3 ], result.owner_ids
        assert_not EspnFranchise.exists?(@source.id)
        assert_not EspnFranchise.exists?(third.id)
      end
    end
  end
end
