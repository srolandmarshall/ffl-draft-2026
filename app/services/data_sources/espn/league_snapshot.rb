module DataSources
  module Espn
    class LeagueSnapshot
      TeamRecord = Data.define(:wins, :losses, :ties, :points_for, :points_against)
      TeamIdentity = Data.define(
        :id, :name, :abbreviation, :owner_ids, :owner_names, :regular_season_rank,
        :playoff_seed, :record, :espn_final_rank, :rank_final, :division_id
      )
      Matchup = Data.define(
        :id, :matchup_period, :scoring_period, :playoff_tier, :home_team_id,
        :away_team_id, :home_points, :away_points, :winner
      )
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
              regular_season_rank: positive_integer(team["playoffSeed"]),
              playoff_seed: playoff_seed(team),
              record: team_record(team),
              espn_final_rank: positive_integer(team["rankCalculatedFinal"]),
              rank_final: positive_integer(team["rankFinal"]),
              division_id: team["divisionId"]
            )
          end
        end
      end

      def matchups
        @matchups ||= payload.fetch("schedule", []).map do |matchup|
          home = matchup["home"]
          away = matchup["away"]
          scoring_periods = [ home, away ].compact.flat_map { |side| side.fetch("pointsByScoringPeriod", {}).keys.map(&:to_i) }.uniq
          Matchup.new(
            id: matchup.fetch("id").to_i,
            matchup_period: matchup.fetch("matchupPeriodId").to_i,
            scoring_period: scoring_periods.one? ? scoring_periods.first : nil,
            playoff_tier: matchup["playoffTierType"].presence || EspnMatchup::REGULAR_SEASON,
            home_team_id: positive_integer(home&.fetch("teamId", nil)),
            away_team_id: positive_integer(away&.fetch("teamId", nil)),
            home_points: decimal(home&.fetch("totalPoints", nil)),
            away_points: decimal(away&.fetch("totalPoints", nil)),
            winner: matchup["winner"].presence || "UNDECIDED"
          )
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

      def playoff_seed(team)
        rank = positive_integer(team["playoffSeed"])
        rank if rank && rank <= settings.raw_snapshot.dig("scheduleSettings", "playoffTeamCount").to_i
      end

      def team_record(team)
        record = team.dig("record", "overall") || {}
        TeamRecord.new(
          wins: record["wins"].to_i,
          losses: record["losses"].to_i,
          ties: record["ties"].to_i,
          points_for: decimal(record["pointsFor"]),
          points_against: decimal(record["pointsAgainst"])
        )
      end

      def positive_integer(value)
        value.to_i if value.to_i.positive?
      end

      def decimal(value)
        BigDecimal(value.to_s).round(2) unless value.nil?
      end
    end
  end
end
