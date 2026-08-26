require "test_helper"

class NflverseHeadshotSyncJobTest < ActiveJob::TestCase
  test "refreshes player data while caching headshots" do
    players(:one).update!(headshot_url: nil)
    test_case = self
    client = Object.new
    client.define_singleton_method(:fetch_players) do
      [ { "espn_id" => "1", "gsis_id" => "00-001", "rookie_season" => "2024", "headshot" => "https://example.com/one" } ]
    end
    client.define_singleton_method(:fetch_actual_stats) do |year:|
      test_case.assert_equal 2025, year
      [ { "player_id" => "00-001", "season" => year.to_s, "season_type" => "REG", "games" => "17", "fantasy_points" => "100" } ]
    end
    client.define_singleton_method(:fetch_headshot) do |url:|
      test_case.assert_equal "https://example.com/one", url
      DataSources::Nflverse::Client::DownloadedImage.new(
        io: StringIO.new("headshot"), content_type: "image/png", extension: "png"
      )
    end

    job = NflverseHeadshotSyncJob.new
    job.define_singleton_method(:client) { client }
    result = job.perform(2026, 2025)

    assert_equal 1, result.with_stats
    assert_equal 1, result.headshots_cached
    assert_equal 100, players(:one).reload.actual_stats["fantasy_points"]
    assert players(:one).headshot.attached?
  end
end
