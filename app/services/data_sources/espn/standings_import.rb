module DataSources
  module Espn
    class StandingsImport
      Record = Struct.new(:wins, :losses, :ties, :points_for, :points_against, keyword_init: true)

      def initialize(season:, identities:)
        @season = season
        @identities = identities
      end

      def call
        records = derived_records
        ranks = complete? ? derived_ranks(records) : {}
        identities.each do |identity|
          team_season = season.team_seasons.find_by!(espn_team_id: attribute(identity, :id).to_i)
          record = records.fetch(team_season.id)
          rank = ranks[team_season.id]
          team_season.update!(
            wins: record.wins,
            losses: record.losses,
            ties: record.ties,
            points_for: record.points_for,
            points_against: record.points_against,
            regular_season_rank: rank,
            playoff_seed: rank && rank <= season.playoff_team_count ? rank : nil
          )
        end
        identities.size
      end

      private

      attr_reader :season, :identities

      def derived_records
        records = season.team_seasons.index_with do
          Record.new(wins: 0, losses: 0, ties: 0, points_for: BigDecimal("0"), points_against: BigDecimal("0"))
        end
        regular_matchups.each do |matchup|
          next unless matchup.home_espn_team_season && matchup.away_espn_team_season
          next if matchup.winner == "UNDECIDED"
          next unless matchup.home_points && matchup.away_points

          home = records.fetch(matchup.home_espn_team_season)
          away = records.fetch(matchup.away_espn_team_season)
          home.points_for += matchup.home_points.to_d
          home.points_against += matchup.away_points.to_d
          away.points_for += matchup.away_points.to_d
          away.points_against += matchup.home_points.to_d
          apply_result(matchup.winner, home, away)
        end
        records.transform_keys(&:id)
      end

      def regular_matchups
        season.matchups.regular_season.where(matchup_period: 1..season.matchup_period_count)
      end

      def complete?
        expected = season.matchup_period_count * season.team_count / 2
        completed = regular_matchups.count do |matchup|
          matchup.winner.in?(%w[HOME AWAY TIE]) && matchup.away_espn_team_season_id && matchup.home_points && matchup.away_points
        end
        expected.positive? && completed == expected
      end

      def derived_ranks(records)
        records.sort_by do |team_season_id, record|
          [ -record.wins, -record.points_for, team_season_id ]
        end.map(&:first).each_with_index.to_h { |team_season_id, index| [ team_season_id, index + 1 ] }
      end

      def apply_result(winner, home, away)
        case winner
        when "HOME"
          home.wins += 1
          away.losses += 1
        when "AWAY"
          away.wins += 1
          home.losses += 1
        when "TIE"
          home.ties += 1
          away.ties += 1
        end
      end

      def attribute(identity, name)
        return identity.public_send(name) if identity.respond_to?(name)
        return unless identity.respond_to?(:[])

        identity[name.to_s] || identity[name]
      end
    end
  end
end
