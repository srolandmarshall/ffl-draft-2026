require "test_helper"

class LeagueHistoriesResultsTest < ActiveSupport::TestCase
  setup do
    @season = espn_seasons(:one)
    @home = espn_team_seasons(:one)
    @home.update!(team_name: "Home Team", regular_season_rank: 1, playoff_finish: 1)
    franchise = @season.league.espn_franchises.create!(key: "AWAY", name: "Away Team", aliases: [ "AWY" ])
    @away = @season.team_seasons.create!(
      espn_franchise: franchise, espn_team_id: 2,
      team_name: "Away Team", team_abbreviation: "AWY",
      owner_ids: [], owner_names: [], regular_season_rank: 2,
      playoff_seed: 2, playoff_finish: 2, wins: 1, losses: 2,
      points_for: 200, points_against: 210
    )
    create_matchup(40, EspnMatchup::REGULAR_SEASON, "HOME", 105, 95)
    create_matchup(41, EspnMatchup::WINNERS_BRACKET, "HOME", 120, 110)
    create_matchup(42, EspnMatchup::CONSOLATION_TIERS.first, "AWAY", 90, 100)
  end

  test "season results render an accessible scrollable standings table and winners bracket" do
    html = render_component(Components::LeagueHistories::SeasonResults.new(season: @season))
    fragment = Nokogiri::HTML.fragment(html)

    assert fragment.at_css(".overflow-x-auto")
    assert_equal "#{@season.season} regular-season standings", fragment.at_css("caption.sr-only").text
    assert fragment.at_css("section[aria-labelledby='season-#{@season.id}-standings']")
    assert fragment.at_css("[role='list'][aria-label='#{@season.season} winners bracket rounds']")
    assert fragment.at_css("article[aria-label*='Home Team'][aria-label*='Away Team']")
  end

  test "record-book components retain tier splits and real accessibility text" do
    book = Leagues::RecordBook.new(@season.league).call
    record_html = render_component(Components::LeagueHistories::RecordBook.new(record_book: book))
    ledger_html = render_component(Components::LeagueHistories::HeadToHead.new(record_book: book))
    rivalry_html = render_component(Components::LeagueHistories::Rivalries.new(record_book: book))

    assert_includes record_html, "All-time regular-season and playoff records by franchise"
    assert_includes record_html, "sr-only"
    assert_includes ledger_html, "1 regular season, 1 winners bracket, 1 consolation"
    assert_includes ledger_html, "tabindex=\"0\""
    assert_includes rivalry_html, "The rivalries"
  end

  private

  def create_matchup(id, tier, winner, home_points, away_points)
    @season.matchups.create!(
      espn_matchup_id: id, matchup_period: id, scoring_period: id,
      playoff_tier: tier, winner:, home_espn_team_season: @home,
      away_espn_team_season: @away, home_points:, away_points:,
      margin: (home_points - away_points).abs
    )
  end

  def render_component(component)
    ApplicationController.renderer.render(component)
  end
end
