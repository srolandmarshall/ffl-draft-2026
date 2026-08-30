module Leagues
  class PlayoffFinishCalculator
    DECIDED_WINNERS = %w[HOME AWAY].freeze

    def initialize(season:)
      @season = season
    end

    def call
      season.team_seasons.update_all(playoff_finish: nil)
      teams = season.team_seasons.where.not(playoff_seed: nil).to_a
      games = season.matchups.winners_bracket.where.not(away_espn_team_season_id: nil).to_a
      return 0 unless complete?(teams, games)

      alive_ids = teams.map(&:id).to_set
      games.group_by(&:matchup_period).sort.each do |_period, round_games|
        losers = round_games.map { |game| loser_id(game) }
        alive_ids.subtract(losers)
        finish = alive_ids.size + 1
        season.team_seasons.where(id: losers).update_all(playoff_finish: finish)
      end
      season.team_seasons.find(alive_ids.sole).update!(playoff_finish: 1)
      teams.size
    end

    private

    attr_reader :season

    def complete?(teams, games)
      teams.size == season.playoff_team_count &&
        games.size == teams.size - 1 &&
        games.all? { |game| game.winner.in?(DECIDED_WINNERS) }
    end

    def loser_id(game)
      game.winner == "HOME" ? game.away_espn_team_season_id : game.home_espn_team_season_id
    end
  end
end
