module DataSources
  module Espn
    class PlayerCatalog
      PlayerIdentity = Data.define(:id, :name, :position)
      POSITION_MAP = PlayerIdSync::POSITION_MAP

      def initialize(rows)
        rows = rows.fetch("players", []) if rows.is_a?(Hash)
        @players_by_id = Array(rows).to_h do |row|
          data = row["player"] || row
          identity = PlayerIdentity.new(
            id: data.fetch("id").to_i,
            name: data["fullName"].presence || "ESPN Player ##{data.fetch('id')}",
            position: POSITION_MAP[data["defaultPositionId"].to_i]
          )
          [ identity.id, identity ]
        end
      end

      def find(id)
        players_by_id[id.to_i] || local_identity(id) || unknown_identity(id)
      end

      private

      attr_reader :players_by_id

      def local_identity(id)
        player = Player.find_by(espn_id: id)
        PlayerIdentity.new(id: id.to_i, name: player.name, position: player.position) if player
      end

      def unknown_identity(id)
        PlayerIdentity.new(id: id.to_i, name: "ESPN Player ##{id}", position: nil)
      end
    end
  end
end
