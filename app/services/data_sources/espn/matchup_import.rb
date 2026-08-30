module DataSources
  module Espn
    class MatchupImport
      def initialize(season:, matchups:)
        @season = season
        @matchups = matchups
      end

      def call
        team_seasons = season.team_seasons.index_by(&:espn_team_id)
        matchup_ids = matchups.map(&:id)
        season.matchups.where.not(espn_matchup_id: matchup_ids).destroy_all
        matchups.each do |matchup|
          season.matchups.find_or_initialize_by(espn_matchup_id: matchup.id).update!(
            matchup_period: matchup.matchup_period,
            scoring_period: matchup.scoring_period,
            playoff_tier: matchup.playoff_tier,
            home_espn_team_season: team_season_for(team_seasons, matchup.home_team_id),
            away_espn_team_season: team_season_for(team_seasons, matchup.away_team_id),
            home_points: matchup.home_points,
            away_points: matchup.away_points,
            margin: margin(matchup),
            winner: matchup.winner
          )
        end
        matchups.size
      end

      private

      attr_reader :season, :matchups

      def team_season_for(team_seasons, team_id)
        team_seasons.fetch(team_id) if team_id
      end

      def margin(matchup)
        return unless matchup.home_points && matchup.away_points

        (matchup.home_points - matchup.away_points).abs
      end
    end
  end
end
