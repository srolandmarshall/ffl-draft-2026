module Leagues
  # Week-level extremes across every decided matchup in a league's history.
  # Shared by the JSON API and the league story page so both quote the same records.
  class Superlatives
    Entry = Data.define(:matchup, :season, :points, :opponent_points, :team_season, :opponent_team_season) do
      def franchise = team_season&.espn_franchise
      def opponent_franchise = opponent_team_season&.espn_franchise
      def team_name = team_season&.team_name
      def opponent_name = opponent_team_season&.team_name
      def margin = (points - opponent_points).abs
      def combined = points + opponent_points
    end

    Result = Data.define(
      :highest_scores, :lowest_scores, :largest_margins, :closest_games,
      :highest_combined, :franchise_bests
    ) do
      # Every franchise's own best week, including the ones that never crack
      # the league-wide top ten.
      def best_week_for(franchise) = franchise_bests[franchise]
    end

    LIMIT = 10

    def self.call(league, limit: LIMIT)
      new(league).call(limit:)
    end

    def initialize(league)
      @league = league
    end

    def call(limit: LIMIT)
      Result.new(
        highest_scores: sides.max_by(limit) { |side| side.points },
        lowest_scores: sides.min_by(limit) { |side| side.points },
        largest_margins: games.max_by(limit) { |side| side.margin },
        closest_games: games.min_by(limit) { |side| side.margin },
        highest_combined: games.max_by(limit) { |side| side.combined },
        franchise_bests: franchise_bests
      )
    end

    private

    attr_reader :league

    def matchups
      @matchups ||= EspnMatchup.decided.where(espn_season_id: league.espn_seasons.select(:id))
        .includes(:espn_season, home_espn_team_season: :espn_franchise, away_espn_team_season: :espn_franchise)
        .select { |matchup| matchup.home_points && matchup.away_points && matchup.margin }
    end

    # One entry per team per matchup, for records about a single team's week.
    def sides
      @sides ||= matchups.flat_map do |matchup|
        [
          entry(matchup, matchup.home_espn_team_season, matchup.home_points, matchup.away_espn_team_season, matchup.away_points),
          entry(matchup, matchup.away_espn_team_season, matchup.away_points, matchup.home_espn_team_season, matchup.home_points)
        ]
      end
    end

    # One entry per matchup, winner's side first, for records about the game itself.
    def games
      @games ||= matchups.map do |matchup|
        home_won = matchup.home_points >= matchup.away_points
        winner, winner_points, loser, loser_points = if home_won
          [ matchup.home_espn_team_season, matchup.home_points, matchup.away_espn_team_season, matchup.away_points ]
        else
          [ matchup.away_espn_team_season, matchup.away_points, matchup.home_espn_team_season, matchup.home_points ]
        end
        entry(matchup, winner, winner_points, loser, loser_points)
      end
    end

    def franchise_bests
      sides.group_by(&:franchise).except(nil).transform_values { |entries| entries.max_by(&:points) }
    end

    def entry(matchup, team_season, points, opponent_team_season, opponent_points)
      Entry.new(
        matchup:, season: matchup.espn_season.season, points: points.to_d,
        opponent_points: opponent_points.to_d, team_season:, opponent_team_season:
      )
    end
  end
end
