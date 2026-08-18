module DataSources
  module FantasyFootballCalculator
    class Import
      POSITION_MAP = { "DEF" => "DST", "PK" => "K" }.freeze
      Result = Data.define(:created, :updated, :meta)

      def initialize(payload, imported_at: Time.current)
        @payload = payload
        @imported_at = imported_at
      end

      def call
        created = 0
        updated = 0

        Player.transaction do
          players.each do |attributes|
            player = find_player(attributes)
            player.new_record? ? created += 1 : updated += 1
            player.update!(attributes.except(:lookup_id).merge(adp_updated_at: imported_at, active: true))
          end
        end

        Result.new(created:, updated:, meta: payload.fetch("meta", {}))
      end

      private

      attr_reader :payload, :imported_at

      def players
        payload.fetch("players").filter_map do |row|
          position = POSITION_MAP.fetch(row["position"], row["position"])
          next unless Player::POSITIONS.include?(position)

          {
            lookup_id: row.fetch("player_id"),
            ffc_id: row.fetch("player_id"),
            name: row.fetch("name"),
            position:,
            pro_team: row.fetch("team"),
            bye_week: row["bye"],
            adp: row["adp"],
            adp_formatted: row["adp_formatted"],
            adp_stdev: row["stdev"],
            adp_times_drafted: row["times_drafted"]
          }
        end
      end

      def find_player(attributes)
        Player.find_by(ffc_id: attributes[:lookup_id]) ||
          Player.find_by(name: attributes[:name], position: attributes[:position], pro_team: attributes[:pro_team]) ||
          Player.new
      end
    end
  end
end
