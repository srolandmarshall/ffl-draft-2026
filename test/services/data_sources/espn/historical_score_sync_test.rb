require "test_helper"

module DataSources
  module Espn
    class HistoricalScoreSyncTest < ActiveSupport::TestCase
      test "imports every stored historical season without rebuilding league history" do
        league = League.create!(name: "Historical Scores", season: 2026, espn_league_id: "12345")
        league.espn_seasons.create!(season: 2024, name: "2024", team_count: 1, settings: {}, teams: [], synced_at: Time.current)
        league.espn_seasons.create!(season: 2025, name: "2025", team_count: 1, settings: {}, teams: [], synced_at: Time.current)
        client = Object.new
        client.define_singleton_method(:fetch_players) do |year:|
          [ { "id" => year, "fullName" => "Player #{year}", "defaultPositionId" => 2, "proTeamId" => 0 } ]
        end
        client.define_singleton_method(:fetch_player_scores) do |year:, league_id:|
          [ Client::PlayerScore.new(espn_id: year, points: year, stats: {}) ]
        end

        result = HistoricalScoreSync.new(league:, client:).call

        assert_equal 2, result.seasons
        assert_equal 2, result.scores
        assert_equal [ 2024, 2025 ], league.league_player_scores.order(:season).pluck(:season)
        assert Player.where(espn_id: [ 2024, 2025 ], active: false).count == 2
      end
    end
  end
end
