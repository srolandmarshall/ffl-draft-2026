class DraftsController < ApplicationController
  PLAYER_LIST_LIMIT = 36

  before_action :authenticate_user_or_bearer_token!
  before_action :set_draft
  before_action :authorize_draft!
  before_action :disable_turbo_cache

  def show
    @selected_team = selected_team
    @picks = @draft.picks.includes(:team, player: Player::PORTRAIT_INCLUDES).to_a
    @pick_elapsed_seconds = pick_elapsed_seconds(@picks)
    @current_pick_elapsed_seconds = @draft.current_pick_elapsed_seconds
    @roster_team = roster_team if params[:view] == "my_team"
    load_available_players unless @draft.complete? || %w[board my_team].include?(params[:view])
    @draft_room = draft_room
  end

  def players
    respond_to do |format|
      format.html do
        @selected_team = selected_team
        load_available_players
        render Components::Drafts::Players.new(room: draft_room, can_make_pick: draft_room.can_make_pick?(current_user))
      end
      format.json { send_data Drafts::PlayerListExport.new(@draft).to_json, filename: player_list_filename("json"), type: :json }
      format.xlsx { send_data Drafts::PlayerListExport.new(@draft).to_xlsx, filename: player_list_filename("xlsx"), type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }
      format.pdf { send_data Drafts::PlayerListExport.new(@draft).to_pdf, filename: player_list_filename("pdf"), type: "application/pdf" }
    end
  end

  private

  def set_draft
    @draft = Draft.includes(draft_entries: :team).find_by!(public_id: params[:public_id])
  end

  def selected_team
    return @selected_team if defined?(@selected_team)

    @selected_team = @draft.teams.joins(:team_memberships).find_by(team_memberships: { user_id: current_user.id })
  end

  def roster_team
    return selected_team unless current_user.commissioner?

    requested_team = @draft.teams.find_by(id: params[:team_id])
    requested_team || selected_team || @draft.teams.first
  end

  def authorize_draft!
    return if current_user.commissioner? || selected_team

    redirect_to root_path, alert: "That email is not assigned to a team in this draft."
  end

  def load_available_players
    scope = @draft.available_players
    @available_teams = scope.reorder(:pro_team).distinct.pluck(:pro_team)
    @player_filters = {
      query: params[:query].to_s.strip,
      positions: Array(params[:positions]) & Player::POSITIONS,
      teams: Array(params[:teams]) & @available_teams
    }

    if @player_filters[:query].present?
      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@player_filters[:query].downcase)}%"
      scope = scope.where("LOWER(players.name) LIKE ?", pattern)
    end
    scope = scope.where(position: @player_filters[:positions]) if @player_filters[:positions].any?
    scope = scope.where(pro_team: @player_filters[:teams]) if @player_filters[:teams].any?

    @available_players = scope.includes(:league_player_scores, **Player::PORTRAIT_INCLUDES).by_ranking.limit(PLAYER_LIST_LIMIT).to_a
  end

  def pick_elapsed_seconds(picks)
    started_at = @draft.started_at

    picks.to_h do |pick|
      elapsed = pick.elapsed_seconds || (started_at ? (pick.created_at - started_at).round : 0)
      started_at = pick.created_at
      [ pick.id, elapsed ]
    end
  end

  def draft_room
    @draft_room ||= DraftRoom.new(
      draft: @draft,
      selected_team: @selected_team,
      picks: @picks || [],
      available_players: @available_players || [],
      available_teams: @available_teams || [],
      player_filters: @player_filters || {},
      roster_team: @roster_team,
      pick_elapsed_seconds: @pick_elapsed_seconds || {},
      current_pick_elapsed_seconds: @current_pick_elapsed_seconds || @draft.current_pick_elapsed_seconds
    )
  end

  def disable_turbo_cache
    response.set_header("Turbo-Cache-Control", "no-cache")
  end

  def player_list_filename(extension)
    "#{@draft.league.name.parameterize}-#{@draft.league.season}-players.#{extension}"
  end
end
