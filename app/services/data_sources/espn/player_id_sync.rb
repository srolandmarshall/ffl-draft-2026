module DataSources
  module Espn
    class PlayerIdSync
      # ESPN's defaultPositionId is not the same numbering used for lineup slot IDs.
      POSITION_MAP = { 1 => "QB", 2 => "RB", 3 => "WR", 4 => "TE", 5 => "K", 16 => "DST" }.freeze
      PRO_TEAM_MAP = {
        1 => "ATL", 2 => "BUF", 3 => "CHI", 4 => "CIN", 5 => "CLE", 6 => "DAL", 7 => "DEN", 8 => "DET",
        9 => "GB", 10 => "TEN", 11 => "IND", 12 => "KC", 13 => "LV", 14 => "LAR", 15 => "MIA", 16 => "MIN",
        17 => "NE", 18 => "NO", 19 => "NYG", 20 => "NYJ", 21 => "PHI", 22 => "ARI", 23 => "PIT", 24 => "LAC",
        25 => "SF", 26 => "SEA", 27 => "TB", 28 => "WAS", 29 => "CAR", 30 => "JAX", 33 => "BAL", 34 => "HOU"
      }.freeze
      Result = Data.define(:matched, :created)

      def initialize(rows)
        @rows = rows
        @players = Player.all.to_a
      end

      def call
        matched = 0
        created = 0

        Player.transaction do
          eligible_rows.each do |row|
            player = match(row)
            if player
              player.update!(player_attributes(row))
              matched += 1
            else
              players << Player.create!(new_player_attributes(row))
              created += 1
            end
          end
        end

        Result.new(matched:, created:)
      end

      private

      attr_reader :rows, :players

      def eligible_rows
        rows.select do |row|
          POSITION_MAP.key?(row["defaultPositionId"]) && PRO_TEAM_MAP.key?(row["proTeamId"])
        end
      end

      def match(row)
        espn_id = row.fetch("id").to_i
        position = POSITION_MAP.fetch(row["defaultPositionId"])
        team = PRO_TEAM_MAP.fetch(row["proTeamId"])
        id_match = players.find { |player| player.espn_id == espn_id }
        return id_match if id_match
        return players.find { |player| player.position == position && player.pro_team == team } if position == "DST"

        exact_match = players.find do |player|
          player.position == position && player.pro_team == team && normalize_name(player.name) == normalize_name(row["fullName"])
        end
        return exact_match if exact_match

        name_matches = players.select do |player|
          player.position == position && normalize_name(player.name) == normalize_name(row["fullName"])
        end
        name_matches.one? ? name_matches.first : nil
      end

      def new_player_attributes(row)
        {
          name: row.fetch("fullName"),
          position: POSITION_MAP.fetch(row.fetch("defaultPositionId")),
          pro_team: PRO_TEAM_MAP.fetch(row.fetch("proTeamId")),
          active: true
        }.merge(player_attributes(row))
      end

      def player_attributes(row)
        attributes = { espn_id: row.fetch("id") }
        return attributes unless row.key?("injuryStatus") || row.key?("injured")

        attributes.merge(
          injury_status: row["injuryStatus"].presence || (row["injured"] ? "INJURED" : "ACTIVE"),
          injury_updated_at: Time.current
        )
      end

      def normalize_name(name)
        ActiveSupport::Inflector.transliterate(name.to_s).downcase.gsub(/\b(jr|sr|ii|iii|iv)\b/, "").gsub(/[^a-z0-9]/, "")
      end
    end
  end
end
