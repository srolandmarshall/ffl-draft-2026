module DataSources
  module Rankings
    class FantasyFootballCalculator < Strategy
      SOURCE = "fantasy_football_calculator".freeze
      POSITION_MAP = { "DEF" => "DST", "PK" => "K" }.freeze

      def initialize(client: DataSources::FantasyFootballCalculator::Client.new, scoring_format:, teams:, year:)
        @client = client
        @scoring_format = scoring_format
        @teams = teams
        @year = year
      end

      def call
        payload = client.fetch_adp(scoring_format:, teams:, year:)
        entries = payload.fetch("players").filter_map do |row|
          position = POSITION_MAP.fetch(row["position"], row["position"])
          next unless Player::POSITIONS.include?(position)

          Entry.new(
            source_id: row.fetch("player_id"),
            espn_id: nil,
            name: row.fetch("name"),
            position:,
            pro_team: row.fetch("team"),
            ranking: row.fetch("adp"),
            position_rank: nil,
            value: nil
          )
        end

        Snapshot.new(
          source: SOURCE,
          entries:,
          positions: Player::POSITIONS,
          meta: payload.fetch("meta", {}),
          attribution: { "text" => "ADP data provided by Fantasy Football Calculator", "url" => "https://fantasyfootballcalculator.com" }
        )
      end

      private

      attr_reader :client, :scoring_format, :teams, :year
    end
  end
end
