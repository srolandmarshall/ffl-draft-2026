module Mcp
  class BaseController < ApplicationController
    before_action :authenticate_user_or_bearer_token!

    private

    def visible_leagues
      return League.all if current_user.commissioner?

      League.joins(teams: :team_memberships)
        .where(team_memberships: { user_id: current_user.id })
        .distinct
    end

    def visible_draft
      draft = Draft.includes(:league, { draft_entries: :team }, { picks: %i[player team] })
        .find_by!(public_id: params[:public_id])
      raise ActiveRecord::RecordNotFound unless visible_leagues.exists?(id: draft.league_id)

      draft
    end

    def render_json(data)
      render json: data
    end
  end
end
