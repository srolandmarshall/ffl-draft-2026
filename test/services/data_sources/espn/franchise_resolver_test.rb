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

      test "scores owner overlap and refuses a franchise already claimed in the season" do
        season = @league.espn_seasons.create!(season: 2026, name: "2026", team_count: 2, settings: {}, teams: [], synced_at: Time.current)
        first = @resolver.resolve(
          abbreviation: "CARR", name: "Example Team 1", espn_team_id: 1,
          season:, owner_ids: [ "shared", "owner-1" ]
        )
        season.team_seasons.create!(
          espn_franchise: first, espn_team_id: 1, team_name: "Example Team 1",
          team_abbreviation: "CARR", owner_ids: [ "shared", "owner-1" ], owner_names: []
        )

        second = @resolver.resolve(
          abbreviation: "CARR", name: "Example Team 2", espn_team_id: 2,
          season:, owner_ids: [ "shared", "owner-2" ]
        )

        assert_not_equal first, second
      end

      test "creates a new franchise when the best owner score is tied" do
        @league.espn_franchises.create!(key: "ONE", name: "One", aliases: [ "ONE" ], owner_ids: [ "shared", "owner-a" ])
        @league.espn_franchises.create!(key: "TWO", name: "Two", aliases: [ "TWO" ], owner_ids: [ "shared", "owner-a" ])
        season = @league.espn_seasons.create!(season: 2026, name: "2026", team_count: 1, settings: {}, teams: [], synced_at: Time.current)

        resolved = @resolver.resolve(
          abbreviation: "NEW", name: "New", espn_team_id: 1,
          season:, owner_ids: [ "shared", "owner-a" ]
        )

        assert_equal "NEW", resolved.key
        assert_equal 3, @league.espn_franchises.count
      end

      test "breaks a shared-owner tie with continuous ESPN team slot history" do
        season_2024 = @league.espn_seasons.create!(season: 2024, name: "2024", team_count: 2, settings: {}, teams: [], synced_at: Time.current)
        season_2025 = @league.espn_seasons.create!(season: 2025, name: "2025", team_count: 2, settings: {}, teams: [], synced_at: Time.current)
        season_2026 = @league.espn_seasons.create!(season: 2026, name: "2026", team_count: 2, settings: {}, teams: [], synced_at: Time.current)

        slot_five = @resolver.resolve(abbreviation: "FIVE", name: "Five", espn_team_id: 5, season: season_2024, owner_ids: [ "shared", "five" ])
        season_2024.team_seasons.create!(
          espn_franchise: slot_five, espn_team_id: 5, team_name: "FIVE", team_abbreviation: "FIVE",
          owner_ids: [ "shared", "five" ], owner_names: []
        )
        slot_six = @resolver.resolve(abbreviation: "SIX", name: "Six", espn_team_id: 6, season: season_2024, owner_ids: [ "shared", "six" ])
        season_2024.team_seasons.create!(
          espn_franchise: slot_six, espn_team_id: 6, team_name: "SIX", team_abbreviation: "SIX",
          owner_ids: [ "shared", "six" ], owner_names: []
        )

        continuing = @resolver.resolve(abbreviation: "SIX", name: "Six", espn_team_id: 6, season: season_2025, owner_ids: [ "shared", "six" ])
        season_2025.team_seasons.create!(
          espn_franchise: continuing, espn_team_id: 6, team_name: "SIX", team_abbreviation: "SIX",
          owner_ids: [ "shared", "six" ], owner_names: []
        )

        resolved = @resolver.resolve(abbreviation: "SIX", name: "Six", espn_team_id: 6, season: season_2026, owner_ids: [ "shared" ])

        assert_equal slot_six, resolved
        assert_not_equal slot_five, resolved
      end

      test "does not use an alias fallback when nonmatching owner ids are present" do
        original = @league.espn_franchises.create!(key: "OLD", name: "Old", aliases: [ "SAME" ], owner_ids: [ "owner-old" ])
        season = @league.espn_seasons.create!(season: 2026, name: "2026", team_count: 1, settings: {}, teams: [], synced_at: Time.current)

        resolved = @resolver.resolve(
          abbreviation: "SAME", name: "New", espn_team_id: 1,
          season:, owner_ids: [ "owner-new" ]
        )

        assert_not_equal original, resolved
      end

      test "twelve-team payload with shared owners and abbreviations remains one-to-one on rerun" do
        season = @league.espn_seasons.create!(season: 2016, name: "2016", team_count: 12, settings: {}, teams: [], synced_at: Time.current)
        identities = 1.upto(12).map do |team_id|
          {
            id: team_id,
            abbreviation: team_id.in?([ 1, 2 ]) ? "CARR" : "T#{team_id}",
            owner_ids: team_id.in?([ 1, 2 ]) ? [ "shared", "owner-#{team_id}" ] : [ "owner-#{team_id}" ]
          }
        end

        2.times do
          identities.each do |identity|
            franchise = @resolver.resolve(
              abbreviation: identity.fetch(:abbreviation), name: "Example Team #{identity.fetch(:id)}",
              espn_team_id: identity.fetch(:id), season:, owner_ids: identity.fetch(:owner_ids)
            )
            season.team_seasons.find_or_initialize_by(espn_team_id: identity.fetch(:id)).update!(
              espn_franchise: franchise,
              team_name: "Example Team #{identity.fetch(:id)}",
              team_abbreviation: identity.fetch(:abbreviation),
              owner_ids: identity.fetch(:owner_ids),
              owner_names: []
            )
          end
        end

        assert_equal 12, @league.espn_franchises.count
        assert_equal 12, season.team_seasons.count
        assert_equal 12, season.team_seasons.distinct.count(:espn_franchise_id)
      end
    end
  end
end
