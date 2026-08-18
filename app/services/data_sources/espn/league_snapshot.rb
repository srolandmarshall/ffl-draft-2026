module DataSources
  module Espn
    class LeagueSnapshot
      TeamIdentity = Data.define(:id, :name, :abbreviation, :owner_ids, :owner_names, :final_rank)
      DraftPick = Data.define(
        :overall_number, :round, :round_pick, :team_id, :team_name, :team_abbreviation,
        :team_owner_ids, :player_id, :player_name, :position
      )

      def self.from_payload(payload)
        new(payload)
      end

      def initialize(payload)
        @payload = payload.deep_dup.freeze
      end

      def season
        payload.fetch("seasonId").to_i
      end

      def name
        settings.league_name.presence || "ESPN League"
      end

      def settings
        @settings ||= LeagueSettings.from_payload(payload)
      end

      def previous_seasons
        payload.fetch("status", {}).fetch("previousSeasons", []).map(&:to_i).select { |year| year < season }
      end

      def teams
        @teams ||= begin
          members = payload.fetch("members", []).index_by { |member| member["id"] }
          payload.fetch("teams", []).map do |team|
            owner_ids = Array(team["owners"])
            owner_names = owner_ids.filter_map do |owner_id|
              member = members[owner_id]
              member && (member["displayName"].presence || [ member["firstName"], member["lastName"] ].compact.join(" ").presence)
            end
            TeamIdentity.new(
              id: team.fetch("id").to_i,
              name: team_name(team),
              abbreviation: team["abbrev"].presence || "T#{team.fetch('id')}",
              owner_ids:,
              owner_names:,
              final_rank: final_rank(team)
            )
          end
        end
      end

      def drafted?
        payload.dig("draftDetail", "drafted") == true
      end

      def draft_picks(player_catalog:)
        team_by_id = teams.index_by(&:id)
        raw_picks = (payload.dig("draftDetail", "picks") || []).reject { |pick| pick["playerId"].to_i == -1 }
        raw_picks.sort_by { |pick| [ pick["roundId"].to_i, pick["roundPickNumber"].to_i ] }.map.with_index(1) do |pick, overall|
          team = team_by_id.fetch(pick.fetch("teamId").to_i)
          player = player_catalog.find(pick.fetch("playerId"))
          DraftPick.new(
            overall_number: pick["overallPickNumber"].presence || overall,
            round: pick.fetch("roundId").to_i,
            round_pick: pick.fetch("roundPickNumber").to_i,
            team_id: team.id,
            team_name: team.name,
            team_abbreviation: team.abbreviation,
            team_owner_ids: team.owner_ids,
            player_id: player.id,
            player_name: player.name,
            position: player.position
          )
        end
      end

      private

      attr_reader :payload

      def team_name(team)
        team["name"].presence || [ team["location"], team["nickname"] ].compact.join(" ").presence || "ESPN Team #{team.fetch('id')}"
      end

      def final_rank(team)
        [ team["rankCalculatedFinal"], team["rankFinal"], team["playoffSeed"] ]
          .map(&:to_i)
          .find(&:positive?)
      end
    end
  end
end
