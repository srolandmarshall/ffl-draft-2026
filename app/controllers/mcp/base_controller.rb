module Mcp
  class BaseController < ApplicationController
    before_action :force_json_format, except: :protected_resource_metadata
    before_action :authenticate_user_or_bearer_token!, except: :protected_resource_metadata
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

    def handle
      status, payload = Mcp::Server.new(
        current_user:,
        espn_client:
      ).call(JSON.parse(request.raw_post))

      return head status unless payload

      render json: payload, status:
    rescue JSON::ParserError
      render json: Mcp::Server.parse_error, status: :bad_request
    end

    def protected_resource_metadata
      render json: Mcp::Oauth.protected_resource_metadata(request.base_url)
    end

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
      raise ActiveRecord::RecordNotFound unless draft.teams.joins(:team_memberships).exists?(
        team_memberships: { user_id: current_user.id }
      )

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

    def espn_client
      credentials = session[:espn_credentials]
      options = { fetcher: request.env["ffl.espn_fetcher"] }.compact
      if credentials.present?
        options.merge!(espn_s2: credentials["espn_s2"], swid: credentials["swid"])
      end
      DataSources::Espn::Client.new(**options)
    end
  end
end
