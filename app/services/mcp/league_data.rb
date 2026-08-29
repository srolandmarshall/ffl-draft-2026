module Mcp
  class LeagueData
    def initialize(league, season: nil)
      @league = league
      @season = season.presence && season.to_i
    end

    def summary
      {
        id: league.id,
        name: league.name,
        season: league.season,
        scoring: { ppr: league.ppr.to_f },
        roster_size: league.roster_size,
        drafts: league.drafts.sort_by(&:created_at).map { |draft| draft_summary(draft) }
      }
    end

    def detail
      summary.merge(
        teams: league.teams.active.in_draft_order.map { |team| team_summary(team) },
        espn: { league_id: league.espn_league_id, last_synced_at: league.espn_synced_at&.iso8601 }
      )
    end

    def history
      {
        league: summary,
        seasons: seasons_scope.includes(draft_picks: :espn_franchise).newest_first.map { |season| season_history(season) }
      }
    end

    private

    attr_reader :league

    def seasons_scope
      scope = league.espn_seasons
      @season ? scope.where(season: @season) : scope
    end

    def draft_summary(draft)
      {
        id: draft.public_id, name: draft.name, status: draft.status,
        started_at: draft.started_at&.iso8601, completed_at: draft.completed_at&.iso8601,
        picks_made: draft.picks.size, total_picks: draft.total_picks
      }
    end

    def team_summary(team)
      { id: team.id, name: team.name, abbreviation: team.abbreviation, owner: team.owner_name, draft_order: team.draft_order }
    end

    def season_history(season)
      {
        season: season.season, name: season.name, team_count: season.team_count, synced_at: season.synced_at.iso8601,
        picks: season.draft_picks.map do |pick|
          {
            overall_pick: pick.overall_number, round: pick.round, pick_in_round: pick.round_pick,
            player: pick.player_name, position: pick.position, team: pick.team_name,
            team_abbreviation: pick.team_abbreviation, owner: pick.espn_franchise&.name
          }
        end
      }
    end
  end
end
