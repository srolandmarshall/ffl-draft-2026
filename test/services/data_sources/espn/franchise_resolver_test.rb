require "test_helper"

module DataSources
  module Espn
    class FranchiseResolverTest < ActiveSupport::TestCase
      setup do
        @league = League.create!(name: "Resolver League", season: 2026)
        @resolver = FranchiseResolver.new(league: @league)
      end

      test "creates a new franchise and links the matching team by abbreviation" do
        team = @league.teams.create!(name: "Red Hawks", owner_name: "Riley", abbreviation: "RED")

        franchise = @resolver.resolve(abbreviation: "red", name: "Red Hawks FC", espn_team_id: 1, season: 2026, owner_ids: [ 501 ])

        assert_equal team, franchise.team
        assert_equal [ 501 ], franchise.owner_ids
        assert_includes franchise.aliases, "red"
      end

      test "matches an existing franchise by owner id even after the team abbreviation changes" do
        original = @resolver.resolve(abbreviation: "OLD", name: "Old Name", espn_team_id: 1, season: 2025, owner_ids: [ 501 ])

        rebranded = @resolver.resolve(abbreviation: "NEW", name: "New Name", espn_team_id: 1, season: 2026, owner_ids: [ 501 ])

        assert_equal original.id, rebranded.id
        assert_includes rebranded.aliases, "OLD"
        assert_includes rebranded.aliases, "NEW"
      end

      test "matches an existing franchise by alias when owner ids do not overlap" do
        original = @resolver.resolve(abbreviation: "OLD", name: "Old Name", espn_team_id: 1, season: 2025, owner_ids: [ 501 ])

        matched = @resolver.resolve(abbreviation: "OLD", name: "Old Name", espn_team_id: 1, season: 2026, owner_ids: [])

        assert_equal original.id, matched.id
      end

      test "does not duplicate aliases or owner ids across repeated resolves" do
        @resolver.resolve(abbreviation: "RED", name: "Red Hawks", espn_team_id: 1, season: 2025, owner_ids: [ 501 ])
        franchise = @resolver.resolve(abbreviation: "RED", name: "Red Hawks", espn_team_id: 1, season: 2026, owner_ids: [ 501 ])

        assert_equal [ "RED" ], franchise.aliases
        assert_equal [ 501 ], franchise.owner_ids
      end

      test "falls back to a stable key derived from abbreviation when nothing else matches" do
        first = @resolver.resolve(abbreviation: "ZZZ", name: "Ghost Team", espn_team_id: 9, season: 2025, owner_ids: [])
        second = @resolver.resolve(abbreviation: "ZZZ", name: "Ghost Team", espn_team_id: 9, season: 2026, owner_ids: [])

        assert_equal first.id, second.id
      end
    end
  end
end
