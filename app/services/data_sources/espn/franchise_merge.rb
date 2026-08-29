module DataSources
  module Espn
    class FranchiseMerge
      def initialize(target:, sources:, name: nil)
        @target = target
        @sources = sources
        @name = name
      end

      def call
        EspnFranchise.transaction do
          ensure_seasons_do_not_overlap!
          aliases = (target.aliases + sources.flat_map(&:aliases)).uniq
          owner_ids = (target.owner_ids + sources.flat_map(&:owner_ids)).uniq
          sources.each do |source|
            source.draft_picks.update_all(espn_franchise_id: target.id)
            source.team_seasons.update_all(espn_franchise_id: target.id)
            source.destroy!
          end
          target.update!(aliases:, owner_ids:, name: name.presence || target.name)
        end
        target
      end

      private

      attr_reader :target, :sources, :name

      def ensure_seasons_do_not_overlap!
        season_ids = [ target, *sources ].flat_map { |franchise| franchise.team_seasons.pluck(:espn_season_id) }
        return if season_ids.uniq.size == season_ids.size

        raise ArgumentError, "Cannot merge franchises that both represent teams in the same ESPN season"
      end
    end
  end
end
