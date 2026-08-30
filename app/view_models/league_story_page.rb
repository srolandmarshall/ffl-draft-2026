# frozen_string_literal: true

# The narrative dossier for a league, told through the franchises that are
# still in it. Everything here is derived from synced ESPN history, so a
# league with no imported seasons renders an empty state rather than blowing up.
LeagueStoryPage = Data.define(
  :league, :dossiers, :seasons, :superlatives, :draft_value, :record_book, :span
) do
  Season = Data.define(:season, :name, :champion, :runner_up, :regular_season_champion, :final) do
    def upset? = champion && regular_season_champion && champion.espn_franchise != regular_season_champion.espn_franchise
  end

  Series = Data.define(:opponent, :wins, :losses, :games) do
    def record = "#{wins}-#{losses}"
  end

  Dossier = Data.define(
    :franchise, :team, :team_seasons, :record, :titles, :runner_ups, :playoff_berths,
    :average_finish, :best_finish, :championship_seasons, :best_week, :best_pick,
    :worst_pick, :nemesis, :prey, :current_drought
  ) do
    def seasons = team_seasons.size
    def name = team&.name.presence || franchise.name
    def owner = team&.owner_name
    def contender? = titles.positive? || runner_ups.positive?
    def points_for = team_seasons.sum { |team_season| team_season.points_for.to_d }
    def points_against = team_seasons.sum { |team_season| team_season.points_against.to_d }
    def point_differential = points_for - points_against
  end

  def self.build(league)
    seasons = league.espn_seasons.includes(
      team_seasons: :espn_franchise,
      matchups: [ { home_espn_team_season: :espn_franchise }, { away_espn_team_season: :espn_franchise } ]
    ).newest_first.to_a
    played = seasons.select { |season| season.team_seasons.any? { |team_season| team_season.regular_season_rank } }

    record_book = Leagues::RecordBook.call(league)
    superlatives = Leagues::Superlatives.call(league)
    draft_value = Leagues::DraftValue.new(league)

    franchises = league.espn_franchises.joins(:team).merge(Team.active)
      .includes(:team, team_seasons: :espn_season).to_a

    dossiers = franchises.filter_map do |franchise|
      dossier(franchise, record_book:, superlatives:, draft_value:)
    end
    dossiers.sort_by! { |dossier| [ -dossier.titles, -dossier.runner_ups, -dossier.record&.win_pct.to_f ] }

    new(
      league:, dossiers:, seasons: played.map { |season| season_story(season) },
      superlatives:, draft_value:, record_book:,
      span: played.map(&:season).minmax
    )
  end

  def self.season_story(season)
    finishers = season.team_seasons.index_by(&:playoff_finish)
    final = season.matchups.select { |matchup| matchup.playoff_tier == EspnMatchup::WINNERS_BRACKET && matchup.margin }
      .max_by { |matchup| [ matchup.matchup_period, matchup.espn_matchup_id ] }
    Season.new(
      season: season.season, name: season.name,
      champion: finishers[1], runner_up: finishers[2],
      regular_season_champion: season.team_seasons.find { |team_season| team_season.regular_season_rank == 1 },
      final:
    )
  end

  def self.dossier(franchise, record_book:, superlatives:, draft_value:)
    team_seasons = franchise.team_seasons.select(&:regular_season_rank)
      .sort_by { |team_season| team_season.espn_season.season }
    return if team_seasons.empty?

    ranks = team_seasons.filter_map(&:regular_season_rank)
    picks = draft_value.for_franchise(franchise)
    series = record_book.head_to_head.select { |pair| pair.franchise_a == franchise || pair.franchise_b == franchise }

    Dossier.new(
      franchise:, team: franchise.team, team_seasons:,
      record: record_book.records.find { |record| record.franchise == franchise },
      titles: team_seasons.count(&:champion?),
      runner_ups: team_seasons.count { |team_season| team_season.playoff_finish == 2 },
      playoff_berths: team_seasons.count(&:made_playoffs?),
      average_finish: ranks.any? ? (ranks.sum.to_f / ranks.size).round(2) : nil,
      best_finish: team_seasons.filter_map(&:playoff_finish).min || ranks.min,
      championship_seasons: team_seasons.select(&:champion?).map { |team_season| team_season.espn_season.season },
      best_week: superlatives.best_week_for(franchise),
      best_pick: picks.select { |pick| pick.value_over_draft.to_i.positive? }.max_by(&:value_over_draft),
      worst_pick: picks.select { |pick| pick.round <= 3 }.min_by { |pick| pick.value_over_draft || 0 },
      nemesis: worst_series(series, franchise),
      prey: best_series(series, franchise),
      current_drought: drought(team_seasons)
    )
  end

  def self.drought(team_seasons)
    since = team_seasons.reverse.take_while { |team_season| !team_season.made_playoffs? }
    since.size
  end

  MIN_SERIES_GAMES = 6

  def self.worst_series(series, franchise)
    ranked_series(series, franchise).select { |pair| pair.games >= MIN_SERIES_GAMES && pair.losses > pair.wins }
      .min_by { |pair| pair.wins - pair.losses }
  end

  def self.best_series(series, franchise)
    ranked_series(series, franchise).select { |pair| pair.games >= MIN_SERIES_GAMES && pair.wins > pair.losses }
      .max_by { |pair| pair.wins - pair.losses }
  end

  def self.ranked_series(series, franchise)
    series.filter_map do |pair|
      mine, theirs = pair.franchise_a == franchise ? [ pair.wins_a, pair.wins_b ] : [ pair.wins_b, pair.wins_a ]
      opponent = pair.franchise_a == franchise ? pair.franchise_b : pair.franchise_a
      Series.new(opponent:, wins: mine, losses: theirs, games: pair.games) if opponent
    end
  end

  private_class_method :season_story, :dossier, :drought,
    :worst_series, :best_series, :ranked_series
end
