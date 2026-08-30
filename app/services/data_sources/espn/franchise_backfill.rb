module DataSources
  module Espn
    class FranchiseBackfill
      Result = Data.define(:team_seasons, :franchises, :picks)

      def initialize(league:)
        @league = league
      end

      def call
        result = nil
        League.transaction do
          reset_franchises
          build_team_seasons
          derive_finishes
          repoint_picks
          link_current_teams
          delete_orphans
          result = Result.new(
            team_seasons: league.espn_team_seasons.count,
            franchises: league.espn_franchises.count,
            picks: picks.where.not(espn_franchise_id: nil).count
          )
        end
        result
      end

      private

      attr_reader :league

      def reset_franchises
        picks.update_all(espn_franchise_id: nil)
        EspnTeamSeason.where(espn_season_id: seasons.select(:id)).update_all(espn_franchise_id: nil)
        league.espn_franchises.destroy_all
        league.espn_franchises.reset
      end

      def build_team_seasons
        resolver = FranchiseResolver.new(league:)
        seasons.order(:season).each do |season|
          Array(season.teams).each do |identity|
            espn_team_id = identity.fetch("id").to_i
            team_name = identity["name"].presence || "ESPN Team #{espn_team_id}"
            team_abbreviation = identity["abbreviation"].presence || "T#{espn_team_id}"
            franchise = resolver.resolve(
              abbreviation: team_abbreviation,
              name: team_name,
              espn_team_id:,
              season:,
              owner_ids: identity["owner_ids"]
            )
            season.team_seasons.find_or_initialize_by(espn_team_id:).update!(
              espn_franchise: franchise,
              espn_team_id:,
              team_name:,
              team_abbreviation:,
              owner_ids: Array(identity["owner_ids"]),
              owner_names: Array(identity["owner_names"]),
              espn_final_rank: positive_integer(identity["espn_final_rank"] || identity["final_rank"]),
              division_id: identity["division_id"]
            )
          end
        end
      end

      def derive_finishes
        seasons.each do |season|
          StandingsImport.new(season:, identities: season.teams).call
          Leagues::PlayoffFinishCalculator.new(season:).call
        end
      end

      def repoint_picks
        seasons.includes(:team_seasons).each do |season|
          franchises_by_team = season.team_seasons.index_by(&:espn_team_id)
          season.draft_picks.each do |pick|
            pick.update!(espn_franchise: franchises_by_team.fetch(pick.espn_team_id).espn_franchise)
          end
        end
      end

      def link_current_teams
        season = seasons.find_by(season: league.season) || seasons.order(season: :desc).first
        return unless season

        team_seasons = season.team_seasons.includes(:espn_franchise).index_by(&:espn_team_id)
        league.teams.where.not(espn_team_id: nil).find_each do |team|
          franchise = team_seasons[team.espn_team_id]&.espn_franchise
          franchise&.update!(team:)
        end
      end

      def delete_orphans
        league.espn_franchises.find_each do |franchise|
          franchise.destroy! if franchise.team_seasons.none? && franchise.draft_picks.none?
        end
      end

      def seasons
        league.espn_seasons
      end

      def picks
        EspnDraftPick.joins(:espn_season).where(espn_seasons: { league_id: league.id })
      end

      def positive_integer(value)
        value.to_i if value.to_i.positive?
      end
    end
  end
end
