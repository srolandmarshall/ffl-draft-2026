module DataSources
  module Rankings
    class LeagueLogs < Strategy
      SOURCE = "league_logs".freeze
      POSITIONS = %w[QB RB WR TE].freeze
      ATTRIBUTION = { "text" => "Powered by LeagueLogs API", "url" => "https://leaguelogs.com" }.freeze
      PROFILES = {
        "redraft-1qb-12t-ppr1" => "Redraft · 1 QB · 12 teams · PPR",
        "redraft-1qb-12t-ppr0_5" => "Redraft · 1 QB · 12 teams · Half PPR",
        "redraft-2qb-12t-ppr1" => "Redraft · 2 QB · 12 teams · PPR"
      }.freeze

      def self.default_profile(league)
        return "redraft-2qb-12t-ppr1" if league&.qb_slots.to_i >= 2
        return "redraft-1qb-12t-ppr1" if league.nil? || league.ppr.to_f >= 0.75

        "redraft-1qb-12t-ppr0_5"
      end

      def initialize(client: DataSources::LeagueLogs::Client.new, profile: PROFILES.first.first)
        raise ArgumentError, "Unknown LeagueLogs profile" unless PROFILES.key?(profile)

        @client = client
        @profile = profile
      end

      def call
        players_payload = client.fetch_players
        market_payload = client.fetch_market(profile:)
        players = players_payload.fetch("data").index_by { |player| player.fetch("sleeperPlayerId") }
        entries = market_payload.fetch("data").filter_map { |row| entry(row, players[row.fetch("sleeperPlayerId")]) }

        Snapshot.new(
          source: SOURCE,
          entries:,
          positions: POSITIONS,
          meta: market_payload.fetch("meta", {}).merge("profile" => profile, "market_rows" => market_payload.fetch("data").size),
          attribution: market_payload.fetch("_attribution", ATTRIBUTION)
        )
      end

      private

      attr_reader :client, :profile

      def entry(row, player)
        return unless player

        Entry.new(
          source_id: row.fetch("sleeperPlayerId"),
          espn_id: player["espnId"].presence&.to_i,
          name: [ player["firstName"], player["lastName"] ].compact.join(" "),
          position: player["position"],
          pro_team: player["team"],
          ranking: row.fetch("overallRank"),
          position_rank: row["positionRank"],
          value: row["value"]
        )
      end
    end
  end
end
