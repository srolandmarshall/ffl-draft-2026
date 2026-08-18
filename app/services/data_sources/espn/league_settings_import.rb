module DataSources
  module Espn
    class LeagueSettingsImport
      Result = Data.define(:attributes)

      def initialize(league:, settings:)
        @league = league
        @settings = settings
      end

      def call
        attributes = settings.draft_defaults
        league.update!(attributes.merge(espn_settings: settings.raw_snapshot, espn_synced_at: Time.current))
        Result.new(attributes:)
      end

      private

      attr_reader :league, :settings
    end
  end
end
