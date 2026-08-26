require "test_helper"

module DataSources
  module Espn
    class FranchiseBackfillTest < ActiveSupport::TestCase
      setup do
        @league = League.create!(name: "Backfill League", season: 2026)
      end

      test "assigns franchises to every pick, reusing one franchise across seasons by owner id" do
        older = @league.espn_seasons.create!(season: 2025, name: "2025", team_count: 1, settings: {}, teams: [
          { "id" => 1, "owner_ids" => [ 501 ] }
        ], synced_at: Time.current)
        newer = @league.espn_seasons.create!(season: 2026, name: "2026", team_count: 1, settings: {}, teams: [
          { "id" => 1, "owner_ids" => [ 501 ] }
        ], synced_at: Time.current)

        older_pick = older.draft_picks.create!(
          overall_number: 1, round: 1, round_pick: 1, espn_team_id: 1,
          team_name: "Old Name", team_abbreviation: "OLD", espn_player_id: 10, player_name: "Player A", position: "RB"
        )
        newer_pick = newer.draft_picks.create!(
          overall_number: 1, round: 1, round_pick: 1, espn_team_id: 1,
          team_name: "New Name", team_abbreviation: "NEW", espn_player_id: 20, player_name: "Player B", position: "WR"
        )

        FranchiseBackfill.new(league: @league).call

        assert_equal older_pick.reload.espn_franchise_id, newer_pick.reload.espn_franchise_id
        assert_equal 1, @league.espn_franchises.count
      end

      test "processes seasons in chronological order so earliest data seeds the franchise identity" do
        season_2024 = @league.espn_seasons.create!(season: 2024, name: "2024", team_count: 1, settings: {}, teams: [
          { "id" => 1, "owner_ids" => [ 501 ] }
        ], synced_at: Time.current)
        season_2026 = @league.espn_seasons.create!(season: 2026, name: "2026", team_count: 1, settings: {}, teams: [
          { "id" => 1, "owner_ids" => [ 501 ] }
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
        other_pick = other_season.draft_picks.create!(
          overall_number: 1, round: 1, round_pick: 1, espn_team_id: 1,
          team_name: "Other", team_abbreviation: "OTH", espn_player_id: 50, player_name: "Player E", position: "K"
        )

        FranchiseBackfill.new(league: @league).call

        assert_nil other_pick.reload.espn_franchise_id
      end
    end
  end
end
