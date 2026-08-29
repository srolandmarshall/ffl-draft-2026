module Mcp
  class BaseController < ApplicationController
    before_action :force_json_format
    before_action :authenticate_user_or_bearer_token!
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

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
      return draft if current_user.commissioner?
      raise ActiveRecord::RecordNotFound unless draft.teams.joins(:team_memberships).exists?(team_memberships: { user_id: current_user.id })

      draft
    end

    def render_json(data)
      render json: data
    end

    def force_json_format
      request.format = :json
    end

    def render_not_found
      render json: { error: "not_found" }, status: :not_found
    end
  end
end
