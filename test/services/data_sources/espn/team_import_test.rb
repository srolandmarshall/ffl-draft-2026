require "test_helper"

module DataSources
  module Espn
    class TeamImportTest < ActiveSupport::TestCase
      Identity = LeagueSnapshot::TeamIdentity

      setup do
        @league = League.create!(name: "Import League", season: 2026)
      end

      test "matches an existing team by franchise alias and updates its espn_team_id" do
        team = @league.teams.create!(name: "Red Hawks", owner_name: "Riley", abbreviation: "RED")
        @league.espn_franchises.create!(key: "RED", name: "Red Hawks", team:, aliases: [ "RHK" ])
        identity = Identity.new(id: 5, name: "Red Hawks", abbreviation: "RHK", owner_ids: [ 1 ], owner_names: [ "Riley" ], final_rank: nil)

        result = TeamImport.new(league: @league, teams: [ identity ]).call

        assert_equal 1, result.matched
        assert_equal 0, result.created
        assert_equal 5, team.reload.espn_team_id
      end

      test "matches an existing team by abbreviation case-insensitively when no franchise alias matches" do
        team = @league.teams.create!(name: "Red Hawks", owner_name: "Riley", abbreviation: "RED")
        identity = Identity.new(id: 5, name: "Different Name", abbreviation: "red", owner_ids: [], owner_names: [], final_rank: nil)

        result = TeamImport.new(league: @league, teams: [ identity ]).call

        assert_equal 1, result.matched
        assert_equal 5, team.reload.espn_team_id
      end

      test "creates a new team and franchise when nothing matches" do
        identity = Identity.new(id: 9, name: "Brand New Squad", abbreviation: "bns", owner_ids: [ 2 ], owner_names: [ "Sam" ], final_rank: nil)

        result = TeamImport.new(league: @league, teams: [ identity ]).call

        assert_equal 1, result.created
        team = @league.teams.find_by(espn_team_id: 9)
        assert_equal "Brand New Squad", team.name
        assert_equal "BNS", team.abbreviation
        assert_equal "Sam", team.owner_name
        franchise = @league.espn_franchises.sole
        assert_equal team, franchise.team
      end

      test "disambiguates an abbreviation collision produced after stripping punctuation" do
        # "B.N.S!" doesn't equal "BNS" as a raw string, so #match's case-insensitive
        # abbreviation lookup misses it and this reaches team creation - where
        # unique_abbreviation strips the punctuation down to the same "BNS" base.
        @league.teams.create!(name: "Manual Team", owner_name: "Manual Owner", abbreviation: "BNS")
        identity = Identity.new(id: 9, name: "Brand New Squad", abbreviation: "B.N.S!", owner_ids: [], owner_names: [], final_rank: nil)

        TeamImport.new(league: @league, teams: [ identity ]).call

        created = @league.teams.find_by(espn_team_id: 9)
        assert_equal "BNS1", created.abbreviation
      end

      test "releases a reused espn_team_id from whichever team held it previously" do
        stale_holder = @league.teams.create!(name: "Stale Holder", owner_name: "Old Owner", abbreviation: "OLD", espn_team_id: 9)
        identity = Identity.new(id: 9, name: "New Claimant", abbreviation: "NEW", owner_ids: [], owner_names: [], final_rank: nil)

        TeamImport.new(league: @league, teams: [ identity ]).call

        assert_nil stale_holder.reload.espn_team_id
        new_team = @league.teams.find_by(name: "New Claimant")
        assert_equal 9, new_team.espn_team_id
      end
    end
  end
end
