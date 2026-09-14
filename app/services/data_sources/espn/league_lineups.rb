module DataSources
  module Espn
    class LeagueLineups
      SLOT_NAMES = {
        0 => "QB", 1 => "TQB", 2 => "RB", 3 => "RB/WR", 4 => "WR", 5 => "WR/TE",
        6 => "TE", 7 => "OP", 8 => "DT", 9 => "DE", 10 => "LB", 11 => "DL",
        12 => "CB", 13 => "S", 14 => "DB", 15 => "DP", 16 => "D/ST", 17 => "K",
        18 => "P", 19 => "HC", 20 => "BE", 21 => "IR", 22 => "INACTIVE", 23 => "FLEX", 24 => "ER",
        25 => "Rookie"
      }.freeze
      INACTIVE_SLOTS = { 20 => "bench", 21 => "injured_reserve", 22 => "inactive", 24 => "injured_reserve" }.freeze

      Player = Data.define(
        :id, :name, :position, :pro_team, :eligible_positions, :injury_status,
        :injured, :percent_owned, :percent_started
      )
      Entry = Data.define(:lineup_slot_id, :lineup_slot, :status, :acquisition_type, :acquired_at, :player)
      Team = Data.define(:id, :name, :abbreviation, :owner_ids, :owner_names, :entries)

      def self.from_payload(payload, scoring_period: nil, fetched_at: Time.current)
        new(payload, requested_scoring_period: scoring_period, fetched_at:)
      end

      attr_reader :fetched_at

      def initialize(payload, requested_scoring_period:, fetched_at:)
        @payload = payload.deep_dup.freeze
        @requested_scoring_period = requested_scoring_period
        @fetched_at = fetched_at
      end

      def scoring_period
        @scoring_period ||= [
          requested_scoring_period,
          payload["scoringPeriodId"],
          payload.dig("status", "latestScoringPeriod")
        ].filter_map { |value| positive_integer(value) }.first
      end

      def teams
        @teams ||= begin
          members = payload.fetch("members", []).index_by { |member| member["id"] }
          payload.fetch("teams")
            .select { |team| team.fetch("isActive", true) }
            .map { |team| parse_team(team, members:) }
        rescue KeyError => error
          raise HttpError, "ESPN roster response is missing #{error.key}"
        end
      end

      private

      attr_reader :payload, :requested_scoring_period

      def parse_team(team, members:)
        owner_ids = Array(team["owners"])
        roster = team["roster"] || team["rosterForCurrentScoringPeriod"] || {}
        Team.new(
          id: team.fetch("id").to_i,
          name: team_name(team),
          abbreviation: team["abbrev"].presence || "T#{team.fetch('id')}",
          owner_ids:,
          owner_names: owner_ids.filter_map { |id| member_name(members[id]) },
          entries: roster.fetch("entries", []).map { |entry| parse_entry(entry) }
        )
      end

      def parse_entry(entry)
        pool_entry = entry.fetch("playerPoolEntry", {})
        player = pool_entry["player"] || entry["player"] || {}
        player_id = entry["playerId"] || pool_entry["id"] || player["id"]
        raise HttpError, "ESPN roster entry is missing playerId" unless player_id

        slot_id = entry.fetch("lineupSlotId").to_i
        Entry.new(
          lineup_slot_id: slot_id,
          lineup_slot: SLOT_NAMES.fetch(slot_id, "ESPN slot ##{slot_id}"),
          status: INACTIVE_SLOTS.fetch(slot_id, "starter"),
          acquisition_type: entry["acquisitionType"],
          acquired_at: timestamp(entry["acquisitionDate"]),
          player: parse_player(player, player_id:)
        )
      rescue KeyError => error
        raise HttpError, "ESPN roster entry is missing #{error.key}"
      end

      def parse_player(player, player_id:)
        ownership = player.fetch("ownership", {})
        position_id = player["defaultPositionId"].to_i
        Player.new(
          id: player_id.to_i,
          name: player["fullName"].presence || "ESPN Player ##{player_id}",
          position: PlayerIdSync::POSITION_MAP[position_id],
          pro_team: PlayerIdSync::PRO_TEAM_MAP[player["proTeamId"].to_i] || "FA",
          eligible_positions: Array(player["eligibleSlots"]).filter_map { |id| SLOT_NAMES[id.to_i] }.uniq,
          injury_status: player["injuryStatus"].presence || "ACTIVE",
          injured: player["injured"] == true,
          percent_owned: decimal(ownership["percentOwned"]),
          percent_started: decimal(ownership["percentStarted"])
        )
      end

      def team_name(team)
        team["name"].presence || [ team["location"], team["nickname"] ].compact.join(" ").presence || "ESPN Team #{team.fetch('id')}"
      end

      def member_name(member)
        return unless member

        member["displayName"].presence || [ member["firstName"], member["lastName"] ].compact.join(" ").presence
      end

      def timestamp(milliseconds)
        Time.zone.at(milliseconds.to_i / 1000.0).utc.iso8601 if milliseconds
      end

      def decimal(value)
        value.to_f.round(2) unless value.nil?
      end

      def positive_integer(value)
        number = value.to_i
        number if number.positive?
      end
    end
  end
end
