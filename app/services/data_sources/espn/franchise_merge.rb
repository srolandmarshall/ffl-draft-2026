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
          aliases = (target.aliases + sources.flat_map(&:aliases)).uniq
          owner_ids = (target.owner_ids + sources.flat_map(&:owner_ids)).uniq
          sources.each do |source|
            source.draft_picks.update_all(espn_franchise_id: target.id)
            source.destroy!
          end
          target.update!(aliases:, owner_ids:, name: name.presence || target.name)
        end
        target
      end

      private

      attr_reader :target, :sources, :name
    end
  end
end
