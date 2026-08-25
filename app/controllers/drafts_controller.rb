class DraftsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_draft
  before_action :authorize_draft!

  def show
    @selected_team = selected_team
    @picks_until_selected_team = @draft.picks_until_team(@selected_team)
    @picks = @draft.picks.includes(:team, player: { headshot_attachment: :blob }).to_a
    @pick_elapsed_seconds = pick_elapsed_seconds(@picks)
    @current_pick_elapsed_seconds = @draft.current_pick_elapsed_seconds
    unless @draft.complete? || params[:view] == "board"
      @available_players = @draft.available_players.includes(:league_player_scores, headshot_attachment: :blob).by_adp
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

  def authorize_draft!
    return if current_user.commissioner? || selected_team

    redirect_to root_path, alert: "That email is not assigned to a team in this draft."
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
