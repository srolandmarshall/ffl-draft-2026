require "test_helper"

class Admin::EspnHistoricalScoreSyncsControllerTest < ActionDispatch::IntegrationTest
  test "commissioner backfills historical player scores" do
    league = leagues(:one)
    league.update!(espn_league_id: "123456")
    result = DataSources::Espn::HistoricalScoreSync::Result.new(seasons: 10, scores: 1_824)
    service = Object.new
    service.define_singleton_method(:call) { result }
    sign_in_as users(:commissioner)

    original_constructor = DataSources::Espn::HistoricalScoreSync.method(:new)
    DataSources::Espn::HistoricalScoreSync.define_singleton_method(:new) { |**| service }
    post admin_league_espn_historical_score_sync_path(league)

    assert_redirected_to admin_league_path(league)
    assert_equal "Imported 1824 player scores across 10 historical seasons.", flash[:notice]
  ensure
    DataSources::Espn::HistoricalScoreSync.define_singleton_method(:new, original_constructor)
  end
end
