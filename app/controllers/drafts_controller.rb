class DraftsController < ApplicationController
  PLAYER_LIST_LIMIT = 36

  before_action :authenticate_user!
  before_action :set_draft
  before_action :authorize_draft!

  def show
    @selected_team = selected_team
    @picks_until_selected_team = @draft.picks_until_team(@selected_team)
    @picks = @draft.picks.includes(:team, player: { headshot_attachment: :blob }).to_a
    @pick_elapsed_seconds = pick_elapsed_seconds(@picks)
    @current_pick_elapsed_seconds = @draft.current_pick_elapsed_seconds
    load_available_players unless @draft.complete? || params[:view] == "board"
  end

  def players
    @selected_team = selected_team
    load_available_players
    render partial: "players", locals: {
      draft: @draft,
      available_players: @available_players,
      available_teams: @available_teams,
      player_filters: @player_filters,
      can_make_pick: @draft.live? && (current_user.commissioner? || @selected_team == @draft.current_team)
    }
  end

  private

  def set_draft
    @draft = Draft.includes(draft_entries: :team).find_by!(public_id: params[:public_id])
  end

  def selected_team
    return @selected_team if defined?(@selected_team)

    @selected_team = @draft.teams.joins(:team_memberships).find_by(team_memberships: { user_id: current_user.id })
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

    @available_players = scope.includes(:league_player_scores, headshot_attachment: :blob).by_adp.limit(PLAYER_LIST_LIMIT).to_a
  end

  def pick_elapsed_seconds(picks)
    started_at = @draft.started_at

    picks.to_h do |pick|
      elapsed = pick.elapsed_seconds || (started_at ? (pick.created_at - started_at).round : 0)
      started_at = pick.created_at
      [ pick.id, elapsed ]
    end
  end
end
