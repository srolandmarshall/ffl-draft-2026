module Leagues
  class RecordBook
    Record = Data.define(
      :franchise, :seasons, :wins, :losses, :ties, :points_for, :points_against,
      :playoff_appearances, :championships, :runner_ups, :regular_season_titles
    ) do
      def games = wins + losses + ties

      def win_pct
        return 0.0 if games.zero?

        ((wins + ties.fdiv(2)) / games).round(3)
      end
    end

    HeadToHead = Data.define(
      :franchise_a, :franchise_b, :games, :wins_a, :wins_b, :ties,
      :points_a, :points_b, :regular_season_games, :playoff_games,
      :consolation_games, :largest_margin, :closest_margin
    ) do
      def leader
        return if wins_a == wins_b

        wins_a > wins_b ? franchise_a : franchise_b
      end
    end

    DynastyArc = Data.define(
      :franchise, :start_season, :end_season, :seasons,
      :playoff_appearances, :championships, :runner_ups
    )

    ConsolationDelta = Data.define(
      :franchise, :season, :regular_season_rank, :espn_final_rank, :places
    )

    ChampionshipOutcome = Data.define(:season, :regular_season_champion, :champion) do
      def same_franchise? = regular_season_champion == champion
    end

    Result = Data.define(
      :records, :head_to_head, :rivalries, :dynasties,
      :championship_outcomes, :consolation_deltas
    )

    class << self
      def call(league)
        Rails.cache.fetch(cache_key(league)) { new(league).call }
      end

      def cache_key(league)
        latest_sync = league.espn_seasons.maximum(:synced_at)&.utc&.iso8601(6) || "empty"
        [ "league-record-book-v1", league.id, latest_sync ]
      end
    end

    def initialize(league)
      @league = league
    end

    def call
      series = head_to_head
      Result.new(
        records: records,
        head_to_head: series,
        rivalries: series.first(5),
        dynasties: dynasties,
        championship_outcomes: championship_outcomes,
        consolation_deltas: consolation_deltas
      )
    end

    private

    attr_reader :league

    def records
      completed_team_seasons.group_by(&:espn_franchise).filter_map do |franchise, seasons|
        next unless franchise

        Record.new(
          franchise:,
          seasons: seasons.size,
          wins: seasons.sum(&:wins),
          losses: seasons.sum(&:losses),
          ties: seasons.sum(&:ties),
          points_for: decimal_sum(seasons, :points_for),
          points_against: decimal_sum(seasons, :points_against),
          playoff_appearances: seasons.count(&:made_playoffs?),
          championships: seasons.count(&:champion?),
          runner_ups: seasons.count { |season| season.playoff_finish == 2 },
          regular_season_titles: seasons.count { |season| season.regular_season_rank == 1 }
        )
      end.sort_by { |record| [ -record.championships, -record.wins, -record.points_for, record.franchise.name ] }
    end

    def head_to_head
      matchup_totals.values.map { |totals| build_head_to_head(totals) }
        .sort_by { |series| [ -series.games, (series.wins_a - series.wins_b).abs, -series.playoff_games, series.franchise_a.name, series.franchise_b.name ] }
    end

    def matchup_totals
      decided_matchups.each_with_object({}) do |matchup, totals_by_pair|
        home = matchup.home_espn_team_season&.espn_franchise
        away = matchup.away_espn_team_season&.espn_franchise
        next unless home && away && home != away

        first, second = [ home, away ].sort_by(&:id)
        totals = totals_by_pair[[ first.id, second.id ]] ||= empty_matchup_totals(first, second)
        add_matchup(totals, matchup, home == first)
      end
    end

    def empty_matchup_totals(first, second)
      {
        franchise_a: first, franchise_b: second, games: 0, wins_a: 0, wins_b: 0, ties: 0,
        points_a: 0.to_d, points_b: 0.to_d, regular_season_games: 0, playoff_games: 0,
        consolation_games: 0, largest_margin: 0.to_d, closest_margin: nil
      }
    end

    def add_matchup(totals, matchup, home_is_first)
      first_points, second_points = home_is_first ? [ matchup.home_points, matchup.away_points ] : [ matchup.away_points, matchup.home_points ]
      totals[:games] += 1
      totals[:points_a] += first_points.to_d
      totals[:points_b] += second_points.to_d
      add_result(totals, matchup, home_is_first)
      add_tier(totals, matchup.playoff_tier)

      margin = (first_points.to_d - second_points.to_d).abs
      totals[:largest_margin] = [ totals[:largest_margin], margin ].max
      totals[:closest_margin] = [ totals[:closest_margin], margin ].compact.min
    end

    def add_result(totals, matchup, home_is_first)
      if matchup.winner == "TIE"
        totals[:ties] += 1
      elsif (matchup.winner == "HOME") == home_is_first
        totals[:wins_a] += 1
      else
        totals[:wins_b] += 1
      end
    end

    def add_tier(totals, tier)
      case tier
      when EspnMatchup::REGULAR_SEASON then totals[:regular_season_games] += 1
      when EspnMatchup::WINNERS_BRACKET then totals[:playoff_games] += 1
      when *EspnMatchup::CONSOLATION_TIERS then totals[:consolation_games] += 1
      end
    end

    def build_head_to_head(totals)
      HeadToHead.new(**totals)
    end

    def dynasties
      completed_team_seasons.group_by(&:espn_franchise).flat_map do |franchise, seasons|
        playoff_runs(franchise, seasons.select(&:made_playoffs?))
      end.sort_by do |arc|
        [ -arc.championships, -arc.playoff_appearances, -arc.end_season, arc.franchise.name ]
      end
    end

    def playoff_runs(franchise, seasons)
      seasons.sort_by { |team_season| team_season.espn_season.season }
        .slice_when { |before, after| after.espn_season.season != before.espn_season.season + 1 }
        .filter_map do |run|
          next if run.size < 2

          DynastyArc.new(
            franchise:,
            start_season: run.first.espn_season.season,
            end_season: run.last.espn_season.season,
            seasons: run.map { |team_season| team_season.espn_season.season },
            playoff_appearances: run.size,
            championships: run.count(&:champion?),
            runner_ups: run.count { |team_season| team_season.playoff_finish == 2 }
          )
        end
    end

    def consolation_deltas
      completed_team_seasons.filter_map do |team_season|
        next unless team_season.espn_franchise && team_season.espn_final_rank
        next if team_season.regular_season_rank == team_season.espn_final_rank

        ConsolationDelta.new(
          franchise: team_season.espn_franchise,
          season: team_season.espn_season.season,
          regular_season_rank: team_season.regular_season_rank,
          espn_final_rank: team_season.espn_final_rank,
          places: team_season.regular_season_rank - team_season.espn_final_rank
        )
      end.sort_by { |delta| [ -delta.places.abs, -delta.season, delta.franchise.name ] }
    end

    def championship_outcomes
      completed_team_seasons.group_by(&:espn_season).filter_map do |season, team_seasons|
        regular = team_seasons.find { |team_season| team_season.regular_season_rank == 1 }&.espn_franchise
        champion = team_seasons.find(&:champion?)&.espn_franchise
        ChampionshipOutcome.new(season: season.season, regular_season_champion: regular, champion:) if regular && champion
      end.sort_by { |outcome| -outcome.season }
    end

    def completed_team_seasons
      @completed_team_seasons ||= league.espn_team_seasons
        .where.not(regular_season_rank: nil)
        .includes(:espn_franchise, :espn_season)
        .to_a
    end

    def decided_matchups
      @decided_matchups ||= EspnMatchup.decided
        .where(espn_season_id: league.espn_seasons.select(:id))
        .includes(home_espn_team_season: :espn_franchise, away_espn_team_season: :espn_franchise)
        .to_a
    end

    def decimal_sum(records, attribute)
      records.sum(0.to_d) { |record| record.public_send(attribute).to_d }
    end
  end
end
