require "test_helper"

module DataSources
  module Rankings
    class ImportTest < ActiveSupport::TestCase
      test "replaces rankings using ESPN IDs and natural identity fallbacks" do
        stale = Player.create!(name: "Stale Ranking", position: "TE", pro_team: "SEA", ranking: 3, ranking_source: "old")
        snapshot = Strategy::Snapshot.new(
          source: "league_logs",
          entries: [
            Strategy::Entry.new(source_id: "one", espn_id: players(:one).espn_id, name: "Different Name", position: "QB", pro_team: "ATL", ranking: 7, position_rank: 2, value: 91.5),
            Strategy::Entry.new(source_id: "two", espn_id: nil, name: players(:two).name, position: players(:two).position, pro_team: players(:two).pro_team, ranking: 12, position_rank: 5, value: 80),
            Strategy::Entry.new(source_id: "missing", espn_id: nil, name: "Missing Player", position: "WR", pro_team: "ATL", ranking: 20, position_rank: 8, value: 60)
          ],
          positions: %w[QB RB WR TE],
          meta: { "playerCount" => 3 },
          attribution: { "text" => "Powered by LeagueLogs API", "url" => "https://leaguelogs.com" }
        )
        strategy = Object.new
        strategy.define_singleton_method(:call) { snapshot }
        imported_at = Time.zone.parse("2026-08-25 12:00:00")

        result = Import.new(strategy:, imported_at:).call

        assert_equal 2, result.updated
        assert_equal 1, result.unmatched
        assert_equal 7, players(:one).reload.ranking
        assert_equal "league_logs", players(:one).ranking_source
        assert_equal 2, players(:one).position_rank
        assert_equal 91.5, players(:one).ranking_value
        assert_equal imported_at, players(:one).ranking_updated_at
        assert_equal 12, players(:two).reload.ranking
        assert_nil stale.reload.ranking
      end

      test "preserves positions outside the strategy coverage" do
        defense = Player.create!(name: "Atlanta Defense", position: "DST", pro_team: "ATL", ranking: 200, ranking_source: "fantasy_football_calculator")
        snapshot = Strategy::Snapshot.new(
          source: "league_logs", entries: [], positions: %w[QB RB WR TE], meta: {},
          attribution: { "text" => "Powered by LeagueLogs API", "url" => "https://leaguelogs.com" }
        )
        strategy = Object.new
        strategy.define_singleton_method(:call) { snapshot }

        Import.new(strategy:).call

        assert_equal 200, defense.reload.ranking
        assert_equal "fantasy_football_calculator", defense.ranking_source
      end

      test "refuses to clear existing rankings when the source returns no entries at all" do
        ranked = Player.create!(name: "Ranked Player", position: "QB", pro_team: "ATL", ranking: 1, ranking_source: "league_logs")
        snapshot = Strategy::Snapshot.new(
          source: "league_logs", entries: [], positions: %w[QB RB WR TE], meta: {},
          attribution: { "text" => "Powered by LeagueLogs API", "url" => "https://leaguelogs.com" }
        )
        strategy = Object.new
        strategy.define_singleton_method(:call) { snapshot }

        assert_raises(Import::EmptySnapshotError) { Import.new(strategy:).call }
        assert_equal 1, ranked.reload.ranking
      end

      test "matches defenses by pro team even when the source names them differently" do
        defense = Player.create!(name: "New York Jets", position: "DST", pro_team: "NYJ")
        snapshot = Strategy::Snapshot.new(
          source: "fantasy_football_calculator",
          entries: [
            Strategy::Entry.new(source_id: 9_001, espn_id: nil, name: "NY Jets Defense", position: "DST", pro_team: "NYJ", ranking: 140, position_rank: 10, value: nil)
          ],
          positions: Player::POSITIONS,
          meta: {},
          attribution: { "text" => "ADP data provided by Fantasy Football Calculator", "url" => "https://fantasyfootballcalculator.com" }
        )
        strategy = Object.new
        strategy.define_singleton_method(:call) { snapshot }

        result = Import.new(strategy:).call

        assert_equal 1, result.updated
        assert_equal 140, defense.reload.ranking
        assert_equal 9_001, defense.ffc_id
      end

      test "reuses a backfilled ffc_id on later imports instead of re-matching by name" do
        player = Player.create!(name: "Original Name", position: "RB", pro_team: "SEA", ffc_id: 4_321)
        snapshot = Strategy::Snapshot.new(
          source: "fantasy_football_calculator",
          entries: [
            Strategy::Entry.new(source_id: 4_321, espn_id: nil, name: "Completely Different Name", position: "RB", pro_team: "SEA", ranking: 5, position_rank: 3, value: nil)
          ],
          positions: Player::POSITIONS,
          meta: {},
          attribution: { "text" => "ADP data provided by Fantasy Football Calculator", "url" => "https://fantasyfootballcalculator.com" }
        )
        strategy = Object.new
        strategy.define_singleton_method(:call) { snapshot }

        result = Import.new(strategy:).call

        assert_equal 1, result.updated
        assert_equal 5, player.reload.ranking
      end
    end
  end
end
