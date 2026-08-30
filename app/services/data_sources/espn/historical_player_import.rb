module DataSources
  module Espn
    class HistoricalPlayerImport
      def initialize(rows)
        @rows = Array(rows.is_a?(Hash) ? rows.fetch("players", []) : rows).map { |row| row.fetch("player", row) }
      end

      def call
        rows.each do |row|
          position = PlayerIdSync::POSITION_MAP[row["defaultPositionId"].to_i]
          next unless position

          espn_id = row.fetch("id").to_i
          next if Player.exists?(espn_id:)

          Player.create!(
            espn_id:,
            name: row["fullName"].presence || "ESPN Player ##{espn_id}",
            position:,
            pro_team: PlayerIdSync::PRO_TEAM_MAP[row["proTeamId"].to_i],
            active: false
          )
        end
      end

      private

      attr_reader :rows
    end
  end
end
