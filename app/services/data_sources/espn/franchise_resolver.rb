module DataSources
  module Espn
    class FranchiseResolver
      def initialize(league:)
        @league = league
      end

      def resolve(abbreviation:, name:, espn_team_id:, season:, owner_ids: [])
        owner_ids = Array(owner_ids).compact.uniq
        season_record = season_record_for(season)
        existing = season_record&.team_seasons&.find_by(espn_team_id:)
        franchise = existing&.espn_franchise
        franchise ||= owner_ids.any? ? owner_match(owner_ids, season_record, espn_team_id) : alias_match(abbreviation, season_record)
        franchise ||= build_franchise(abbreviation, espn_team_id, season_record&.season || season)
        team = current_team_for(abbreviation, season_record&.season || season.to_i)
        franchise.team ||= team
        franchise.name = franchise.team&.name || name
        franchise.aliases = (franchise.aliases + [ abbreviation ]).compact.uniq
        franchise.owner_ids = (franchise.owner_ids + owner_ids).uniq
        franchise.save!
        franchise
      end

      private

      attr_reader :league

      def season_record_for(season)
        return season if season.is_a?(EspnSeason)

        league.espn_seasons.find_by(season:)
      end

      def owner_match(owner_ids, season, espn_team_id)
        scored = league.espn_franchises.filter_map do |candidate|
          candidate_owner_ids = owner_ids_for(candidate, season)
          overlap = (candidate_owner_ids & owner_ids).size
          next if overlap.zero?

          union = (candidate_owner_ids | owner_ids).size
          [ candidate, [ overlap, Rational(overlap, union), slot_continuity?(candidate, season, espn_team_id) ? 1 : 0 ] ]
        end
        return if scored.empty?

        best_score = scored.map(&:last).max
        best = scored.select { |_, score| score == best_score }
        return unless best.one?

        candidate = best.first.first
        candidate unless claimed_franchise_ids(season).include?(candidate.id)
      end

      # A franchise's owner_ids is an all-time display aggregate. Matching with it
      # makes a later co-owner look like they owned every earlier incarnation.
      # Match against the most recent identity before this season instead, and use
      # a continuous ESPN slot only as the final tie-breaker: slots can be reused.
      def owner_ids_for(franchise, season)
        latest = latest_team_season_for(franchise, season)
        latest ? Array(latest.owner_ids) : Array(franchise.owner_ids)
      end

      def slot_continuity?(franchise, season, espn_team_id)
        previous = previous_season_for(season)
        return false unless previous

        previous.team_seasons.exists?(espn_franchise: franchise, espn_team_id:)
      end

      def latest_team_season_for(franchise, season)
        scope = franchise.team_seasons.joins(:espn_season).where(espn_seasons: { league_id: league.id })
        scope = scope.where("espn_seasons.season < ?", season.season) if season
        scope.order("espn_seasons.season DESC").first
      end

      def previous_season_for(season)
        return unless season

        league.espn_seasons.where("season < ?", season.season).order(season: :desc).first
      end

      def alias_match(abbreviation, season)
        candidates = league.espn_franchises.select do |candidate|
          candidate.matches_alias?(abbreviation) && !claimed_franchise_ids(season).include?(candidate.id)
        end
        candidates.one? ? candidates.first : nil
      end

      def claimed_franchise_ids(season)
        return [] unless season

        season.team_seasons.where.not(espn_franchise_id: nil).pluck(:espn_franchise_id)
      end

      def build_franchise(abbreviation, espn_team_id, season)
        base = key_for(abbreviation, espn_team_id, season)
        key = base
        key = "#{base}-#{season}-#{espn_team_id}" if league.espn_franchises.exists?(key:)
        suffix = 2
        while league.espn_franchises.exists?(key:)
          key = "#{base}-#{season}-#{espn_team_id}-#{suffix}"
          suffix += 1
        end
        league.espn_franchises.build(key:)
      end

      def current_team_for(abbreviation, season)
        return unless season == league.season

        league.teams.find { |candidate| candidate.abbreviation.casecmp?(abbreviation.to_s) }
      end

      def key_for(abbreviation, espn_team_id, season)
        normalized = ActiveSupport::Inflector.transliterate(abbreviation.to_s).upcase.gsub(/[^A-Z0-9]/, "")
        normalized.presence || "ESPN-#{espn_team_id}-#{season}"
      end
    end
  end
end
