module Mcp
  class LineupData
    def initialize(league, snapshot)
      @league = league
      @snapshot = snapshot
    end

    def as_json
      {
        league: {
          id: league.id,
          espn_league_id: league.espn_league_id,
          name: league.name,
          season: league.season
        },
        scoring_period: snapshot.scoring_period,
        fetched_at: snapshot.fetched_at.utc.iso8601,
        teams: snapshot.teams.map { |team| team_data(team) }
      }
    end

    private

    attr_reader :league, :snapshot

    def team_data(team)
      local_team = league.teams.find { |candidate| candidate.espn_team_id == team.id }
      {
        espn_team_id: team.id,
        team_id: local_team&.id,
        name: team.name,
        abbreviation: team.abbreviation,
        owners: team.owner_names.presence || Array(local_team&.owner_name),
        lineup: team.entries.map { |entry| entry_data(entry) }
      }
    end

    def entry_data(entry)
      {
        lineup_slot_id: entry.lineup_slot_id,
        lineup_slot: entry.lineup_slot,
        status: entry.status,
        acquisition_type: entry.acquisition_type,
        acquired_at: entry.acquired_at,
        player: {
          espn_id: entry.player.id,
          name: entry.player.name,
          position: entry.player.position,
          eligible_positions: entry.player.eligible_positions,
          pro_team: entry.player.pro_team,
          injury_status: entry.player.injury_status,
          injured: entry.player.injured,
          percent_owned: entry.player.percent_owned,
          percent_started: entry.player.percent_started
        }
      }
    end
  end
end
