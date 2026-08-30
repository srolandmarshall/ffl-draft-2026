require "test_helper"

module DataSources
  module Espn
    class FranchiseBackfillTest < ActiveSupport::TestCase
      setup do
        @league = League.create!(name: "Backfill League", season: 2026)
      end

      test "assigns franchises to every pick, reusing one franchise across seasons by owner id" do
        older = @league.espn_seasons.create!(season: 2025, name: "2025", team_count: 1, settings: {}, teams: [
          { "id" => 1, "name" => "Old Name", "abbreviation" => "OLD", "owner_ids" => [ 501 ], "final_rank" => 4 }
        ], synced_at: Time.current)
        newer = @league.espn_seasons.create!(season: 2026, name: "2026", team_count: 1, settings: {}, teams: [
          { "id" => 1, "name" => "New Name", "abbreviation" => "NEW", "owner_ids" => [ 501 ], "final_rank" => 2 }
        ], synced_at: Time.current)

        older_pick = older.draft_picks.create!(
          overall_number: 1, round: 1, round_pick: 1, espn_team_id: 1,
          team_name: "Old Name", team_abbreviation: "OLD", espn_player_id: 10, player_name: "Player A", position: "RB"
        )
        newer_pick = newer.draft_picks.create!(
          overall_number: 1, round: 1, round_pick: 1, espn_team_id: 1,
          team_name: "New Name", team_abbreviation: "NEW", espn_player_id: 20, player_name: "Player B", position: "WR"
        )
        orphan = @league.espn_franchises.create!(key: "ORPHAN", name: "Orphan", aliases: [ "OLD" ])

        result = FranchiseBackfill.new(league: @league).call

        assert_equal older_pick.reload.espn_franchise_id, newer_pick.reload.espn_franchise_id
        assert_equal 1, @league.espn_franchises.count
        assert_equal 2, result.team_seasons
        assert_equal [ 4, 2 ], @league.espn_team_seasons.order(:espn_season_id).pluck(:espn_final_rank)
        assert @league.espn_team_seasons.where.not(regular_season_rank: nil).none?
        assert_not EspnFranchise.exists?(orphan.id)
      end

      test "processes seasons in chronological order so earliest data seeds the franchise identity" do
        season_2024 = @league.espn_seasons.create!(season: 2024, name: "2024", team_count: 1, settings: {}, teams: [
          { "id" => 1, "name" => "Earlier", "abbreviation" => "ERL", "owner_ids" => [ 501 ] }
        ], synced_at: Time.current)
        season_2026 = @league.espn_seasons.create!(season: 2026, name: "2026", team_count: 1, settings: {}, teams: [
          { "id" => 1, "name" => "Later", "abbreviation" => "LTR", "owner_ids" => [ 501 ] }
        ], synced_at: Time.current)

        season_2026.draft_picks.create!(
          overall_number: 2, round: 1, round_pick: 2, espn_team_id: 1,
          team_name: "Later Pick", team_abbreviation: "LTR", espn_player_id: 30, player_name: "Player C", position: "TE"
        )
        season_2024.draft_picks.create!(
          overall_number: 1, round: 1, round_pick: 1, espn_team_id: 1,
          team_name: "Earlier Pick", team_abbreviation: "ERL", espn_player_id: 40, player_name: "Player D", position: "QB"
        )

        FranchiseBackfill.new(league: @league).call

        franchise = @league.espn_franchises.sole
        assert_equal %w[ERL LTR], franchise.aliases
      end

      test "leaves picks for other leagues untouched" do
        other_league = League.create!(name: "Other League", season: 2026)
        other_season = other_league.espn_seasons.create!(season: 2026, name: "2026", team_count: 1, settings: {}, teams: [], synced_at: Time.current)
        other_franchise = other_league.espn_franchises.create!(key: "OTH", name: "Other", aliases: [ "OTH" ])
        other_pick = other_season.draft_picks.create!(
          espn_franchise: other_franchise,
          overall_number: 1, round: 1, round_pick: 1, espn_team_id: 1,
          team_name: "Other", team_abbreviation: "OTH", espn_player_id: 50, player_name: "Player E", position: "K"
        )

        FranchiseBackfill.new(league: @league).call

        assert_equal other_franchise, other_pick.reload.espn_franchise
      end

      test "repairs shared owners and abbreviations into twelve distinct season identities" do
        seasons = [ 2016, 2017, 2018 ].map do |year|
          identities = 1.upto(12).map do |team_id|
            owners = team_id.in?([ 1, 2 ]) ? [ "shared-owner", "owner-#{team_id}" ] : [ "owner-#{team_id}" ]
            abbreviation = team_id.in?([ 1, 2 ]) ? "CARR" : "T#{team_id}"
            { "id" => team_id, "name" => "Example Team #{team_id}", "abbreviation" => abbreviation, "owner_ids" => owners, "final_rank" => team_id }
          end
          season = @league.espn_seasons.create!(season: year, name: year.to_s, team_count: 12, settings: {}, teams: identities, synced_at: Time.current)
          identities.each do |identity|
            team_id = identity.fetch("id")
            season.draft_picks.create!(
              overall_number: team_id, round: 1, round_pick: team_id, espn_team_id: team_id,
              team_name: identity.fetch("name"), team_abbreviation: identity.fetch("abbreviation"),
              espn_player_id: year * 100 + team_id, player_name: "Player #{team_id}", position: "RB"
            )
          end
          season
        end
        original_season_ids = EspnDraftPick.where(espn_season: seasons).order(:id).pluck(:espn_season_id)

        FranchiseBackfill.new(league: @league).call
        FranchiseBackfill.new(league: @league).call

        seasons.each do |season|
          assert_equal 12, season.team_seasons.count
          assert_equal 12, season.team_seasons.distinct.count(:espn_franchise_id)
        end
        assert_equal 12, @league.espn_franchises.count
        assert_equal original_season_ids, EspnDraftPick.where(espn_season: seasons).order(:id).pluck(:espn_season_id)
      end
    end
  end
end
