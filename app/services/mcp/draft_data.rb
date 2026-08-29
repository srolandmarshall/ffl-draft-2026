module Mcp
  class DraftData
    def initialize(draft)
      @draft = draft
    end

    def summary
      {
        league: { id: draft.league_id, name: draft.league.name, season: draft.league.season },
        draft: {
          id: draft.public_id, name: draft.name, status: draft.status, draft_type: draft.draft_type,
          rounds: draft.rounds, picks_made: draft.picks.size, total_picks: draft.total_picks,
          next_overall_pick: draft.next_overall_number, current_round: draft.current_round,
          current_team: draft.current_team && team_data(draft.current_team),
          started_at: draft.started_at&.iso8601, completed_at: draft.completed_at&.iso8601
        },
        teams: draft.draft_entries.map { |entry| team_data(entry.team).merge(draft_position: entry.position) }
      }
    end

    def results
      summary.merge(picks: draft.picks.map { |pick| pick_data(pick) })
    end

    private

    attr_reader :draft

    def pick_data(pick)
      {
        overall_pick: pick.overall_number, round: pick.round,
        player: { name: pick.player.name, position: pick.player.position, pro_team: pick.player.pro_team, espn_id: pick.player.espn_id },
        team: team_data(pick.team), elapsed_seconds: pick.elapsed_seconds, picked_at: pick.created_at.iso8601
      }
    end

    def team_data(team)
      { id: team.id, name: team.name, abbreviation: team.abbreviation, owner: team.owner_name }
    end
  end
end
