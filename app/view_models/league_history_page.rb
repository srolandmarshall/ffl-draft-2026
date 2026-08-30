# frozen_string_literal: true

LeagueHistoryPage = Data.define(:league, :seasons, :tendencies, :record_book) do
  def self.build(league)
    imported_seasons = league.espn_seasons.includes(
      :draft_picks,
      team_seasons: :espn_franchise,
      matchups: [ { home_espn_team_season: :espn_franchise }, { away_espn_team_season: :espn_franchise } ]
    ).newest_first
    seasons = imported_seasons.select { |season| season.draft_picks.any? }
    franchises = league.espn_franchises.joins(:team).merge(Team.active)
      .includes(:team, :team_seasons, draft_picks: :espn_season).to_a
    franchises.sort_by! { |franchise| [ franchise.team.draft_order || 999, franchise.name ] }
    tendencies = Drafts::HistoricalTendencies.new(franchises:, seasons:).call
    tendencies.sort_by! { |tendency| [ -tendency.playoff_finishes.values.count(1), -tendency.seasons ] }

    new(league:, seasons:, tendencies:, record_book: Leagues::RecordBook.call(league))
  end
end
