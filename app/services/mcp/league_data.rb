module Mcp
  class LeagueData
    TIER_FILTERS = {
      "regular" => [ EspnMatchup::REGULAR_SEASON ],
      "winners" => [ EspnMatchup::WINNERS_BRACKET ],
      "playoffs" => [ EspnMatchup::WINNERS_BRACKET ],
      "consolation" => EspnMatchup::CONSOLATION_TIERS
    }.freeze

    def initialize(league, season: nil, include_picks: true)
      @league = league
      @season = season.presence && season.to_i
      @include_picks = include_picks
    end

    def summary
      {
        id: league.id,
        name: league.name,
        season: league.season,
        scoring: { ppr: league.ppr.to_f },
        roster_size: league.roster_size,
        drafts: league.drafts.sort_by(&:created_at).map { |draft| draft_summary(draft) }
      }
    end

    def detail
      summary.merge(
        teams: league.teams.active.in_draft_order.map { |team| team_summary(team) },
        espn: { league_id: league.espn_league_id, last_synced_at: league.espn_synced_at&.iso8601 }
      )
    end

    def history
      { league: summary, seasons: loaded_seasons.map { |season| season_history(season) } }
    end

    def standings
      { league: league_identity, seasons: loaded_seasons.map { |season| season_outcomes(season) } }
    end

    def matchups(tier: nil)
      scope = matchups_scope
      scope = scope.where(playoff_tier: tiers_for(tier)) if tier.present?
      { league: league_identity, matchups: scope.map { |matchup| matchup_data(matchup) } }
    end

    def records
      book = Leagues::RecordBook.call(league)
      {
        league: league_identity,
        records: book.records.map { |record| record_data(record) },
        head_to_head: book.head_to_head.map { |series| head_to_head_data(series) },
        rivalries: book.rivalries.map { |series| head_to_head_data(series) },
        dynasties: book.dynasties.map { |arc| dynasty_data(arc) },
        championship_outcomes: book.championship_outcomes.map { |outcome| championship_outcome_data(outcome) },
        consolation_rank_audit: book.consolation_deltas.map { |delta| consolation_delta_data(delta) },
        superlatives: superlatives,
        season_movements: season_movements
      }
    end

    def player_scores
      scores = league.league_player_scores.includes(:player).where(season: @season).order(:season, points: :desc).to_a
      {
        league: league_identity,
        season: @season,
        player_scores: scores_by_position(scores)
      }
    end

    private

    attr_reader :league, :include_picks

    def seasons_scope
      scope = league.espn_seasons
      @season ? scope.where(season: @season) : scope
    end

    def loaded_seasons
      @loaded_seasons ||= seasons_scope.includes({ draft_picks: :espn_franchise }, team_seasons: :espn_franchise).newest_first.to_a
    end

    def matchups_scope
      EspnMatchup.where(espn_season_id: seasons_scope.select(:id))
        .includes(:espn_season, home_espn_team_season: :espn_franchise, away_espn_team_season: :espn_franchise)
        .order("espn_seasons.season DESC", :matchup_period, :espn_matchup_id)
        .references(:espn_season)
    end

    def tiers_for(tier)
      TIER_FILTERS.fetch(tier.to_s.downcase) { [ tier.to_s.upcase ] }
    end

    def draft_summary(draft)
      {
        id: draft.public_id, name: draft.name, status: draft.status,
        started_at: draft.started_at&.iso8601, completed_at: draft.completed_at&.iso8601,
        picks_made: draft.picks.size, total_picks: draft.total_picks
      }
    end

    def team_summary(team)
      { id: team.id, name: team.name, abbreviation: team.abbreviation, owner: team.owner_name, draft_order: team.draft_order }
    end

    def season_history(season)
      data = {
        season: season.season, name: season.name, team_count: season.team_count,
        synced_at: season.synced_at.iso8601, standings: standings_data(season),
        champion: team_outcome_data(season.team_seasons.find(&:champion?)),
        regular_season_champion: team_outcome_data(season.team_seasons.find { |team_season| team_season.regular_season_rank == 1 })
      }
      data[:picks] = season.draft_picks.map { |pick| pick_data(pick) } if include_picks
      data
    end

    def season_outcomes(season)
      {
        season: season.season, name: season.name, standings: standings_data(season),
        champion: team_outcome_data(season.team_seasons.find(&:champion?)),
        regular_season_champion: team_outcome_data(season.team_seasons.find { |team_season| team_season.regular_season_rank == 1 })
      }
    end

    def pick_data(pick)
      {
        overall_pick: pick.overall_number, round: pick.round, pick_in_round: pick.round_pick,
        player: pick.player_name, position: pick.position, team: pick.team_name,
        team_abbreviation: pick.team_abbreviation, franchise: franchise_data(pick.espn_franchise)
      }
    end

    def standings_data(season)
      season.team_seasons.sort_by { |team_season| team_season.regular_season_rank || Float::INFINITY }
        .map { |team_season| team_season_data(team_season) }
    end

    def team_season_data(team_season)
      {
        espn_team_id: team_season.espn_team_id,
        franchise: franchise_data(team_season.espn_franchise),
        team: team_season.team_name,
        team_abbreviation: team_season.team_abbreviation,
        record: {
          wins: team_season.wins, losses: team_season.losses, ties: team_season.ties,
          win_pct: team_season.win_pct
        },
        points_for: team_season.points_for&.to_f,
        points_against: team_season.points_against&.to_f,
        regular_season_rank: team_season.regular_season_rank,
        playoff_seed: team_season.playoff_seed,
        playoff_finish: team_season.playoff_finish,
        playoff_result: team_season.playoff_result_label
      }
    end

    def team_outcome_data(team_season)
      return unless team_season

      {
        espn_team_id: team_season.espn_team_id,
        team: team_season.team_name,
        team_abbreviation: team_season.team_abbreviation,
        franchise: franchise_data(team_season.espn_franchise)
      }
    end

    def matchup_data(matchup)
      {
        id: matchup.espn_matchup_id,
        season: matchup.espn_season.season,
        matchup_period: matchup.matchup_period,
        scoring_period: matchup.scoring_period,
        tier: matchup.playoff_tier,
        winner: matchup.winner,
        home: matchup_side(matchup.home_espn_team_season, matchup.home_points),
        away: matchup_side(matchup.away_espn_team_season, matchup.away_points),
        margin: matchup.margin&.to_f
      }
    end

    def matchup_side(team_season, points)
      return unless team_season

      {
        espn_team_id: team_season.espn_team_id,
        team: team_season.team_name,
        franchise: franchise_data(team_season.espn_franchise),
        points: points&.to_f
      }
    end

    def record_data(record)
      {
        franchise: franchise_data(record.franchise), seasons: record.seasons,
        wins: record.wins, losses: record.losses, ties: record.ties, win_pct: record.win_pct,
        points_for: record.points_for.to_f, points_against: record.points_against.to_f,
        playoff_appearances: record.playoff_appearances, championships: record.championships,
        runner_ups: record.runner_ups, regular_season_titles: record.regular_season_titles
      }
    end

    def head_to_head_data(series)
      {
        franchise_a: franchise_data(series.franchise_a), franchise_b: franchise_data(series.franchise_b),
        games: series.games, wins_a: series.wins_a, wins_b: series.wins_b, ties: series.ties,
        points_a: series.points_a.to_f, points_b: series.points_b.to_f,
        regular_season_games: series.regular_season_games, playoff_games: series.playoff_games,
        consolation_games: series.consolation_games,
        largest_margin: series.largest_margin.to_f, closest_margin: series.closest_margin&.to_f
      }
    end

    def dynasty_data(arc)
      {
        franchise: franchise_data(arc.franchise), start_season: arc.start_season,
        end_season: arc.end_season, seasons: arc.seasons,
        playoff_appearances: arc.playoff_appearances,
        championships: arc.championships, runner_ups: arc.runner_ups
      }
    end

    def championship_outcome_data(outcome)
      {
        season: outcome.season,
        regular_season_champion: franchise_data(outcome.regular_season_champion),
        champion: franchise_data(outcome.champion),
        same_franchise: outcome.same_franchise?,
        championship_game: championship_game_data(outcome.season)
      }
    end

    def consolation_delta_data(delta)
      {
        franchise: franchise_data(delta.franchise), season: delta.season,
        regular_season_rank: delta.regular_season_rank,
        espn_final_rank: delta.espn_final_rank, places: delta.places
      }
    end

    def franchise_data(franchise)
      return unless franchise

      { id: franchise.id, name: franchise.name }
    end

    def scores_by_position(scores)
      scores.group_by { |score| score.player.position }.flat_map do |_position, position_scores|
        position_scores.sort_by { |score| -score.points }.each_with_index.map do |score, index|
          {
            player: { espn_id: score.player.espn_id, name: score.player.name, position: score.player.position },
            points: score.points.to_f,
            position_rank: index + 1
          }
        end
      end.sort_by { |score| [ score.dig(:player, :position), score[:position_rank] ] }
    end

    def championship_game_data(season)
      espn_season = league.espn_seasons.find_by(season:)
      matchup = espn_season&.matchups&.winners_bracket&.order(matchup_period: :desc, espn_matchup_id: :desc)&.first
      matchup_data(matchup) if matchup
    end

    def superlatives
      book = Leagues::Superlatives.call(league)
      {
        highest_single_week_scores: book.highest_scores.map { |entry| matchup_data(entry.matchup) },
        lowest_single_week_scores: book.lowest_scores.map { |entry| matchup_data(entry.matchup) },
        largest_margins: book.largest_margins.map { |entry| matchup_data(entry.matchup) },
        closest_games: book.closest_games.map { |entry| matchup_data(entry.matchup) },
        highest_combined_scores: book.highest_combined.map { |entry| matchup_data(entry.matchup) }
      }
    end

    def season_movements
      league.espn_team_seasons.includes(:espn_franchise, :espn_season).where.not(regular_season_rank: nil)
        .group_by(&:espn_franchise).flat_map do |franchise, seasons|
          next [] unless franchise

          seasons.sort_by { |team_season| team_season.espn_season.season }.each_cons(2).map do |before, after|
            {
              franchise: franchise_data(franchise),
              from_season: before.espn_season.season,
              to_season: after.espn_season.season,
              from_rank: before.regular_season_rank,
              to_rank: after.regular_season_rank,
              places: before.regular_season_rank - after.regular_season_rank
            }
          end
        end.sort_by { |movement| [ -movement[:places].abs, -movement[:to_season] ] }
    end

    def league_identity
      { id: league.id, name: league.name, season: league.season }
    end
  end
end
