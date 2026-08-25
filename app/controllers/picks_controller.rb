class PicksController < ApplicationController
  before_action :authenticate_user!

  def create
    draft = Draft.find_by!(public_id: params[:draft_public_id])
    team = if current_user.commissioner?
      draft.current_team
    else
      draft.teams.joins(:team_memberships).find_by(team_memberships: { user_id: current_user.id })
    end
    raise Drafts::MakePick::InvalidPick, "Your email is not assigned to a team in this draft." unless team

    player = Player.find(params.require(:player_id))
    Drafts::MakePick.new(draft:, team:, player:).call
    respond_to do |format|
      # The committed pick broadcasts targeted updates to every draft viewer.
      # Re-navigating the enclosing room frame here duplicates that work and
      # causes the whole room to disappear and reflow between broadcasts.
      format.turbo_stream { head :no_content }
      format.html { redirect_to draft_path(draft.public_id), notice: "#{team.name} has picked #{player.name} (#{player.position})" }
    end
  rescue Drafts::MakePick::InvalidPick => error
    redirect_to draft_path(params[:draft_public_id]), alert: error.message
  end

  def destroy
    draft = Draft.find_by!(public_id: params[:draft_public_id])
    unless current_user.commissioner?
      redirect_to root_path, alert: "Commissioner access is required."
      return
    end

    pick = draft.picks.find(params[:id])
    Drafts::UndoPick.new(draft:, pick:).call
    redirect_to draft_path(draft.public_id), notice: "Undid #{pick.team.name}'s pick of #{pick.player.name}. The clock is paused."
  rescue Drafts::UndoPick::InvalidUndo => error
    redirect_to draft_path(params[:draft_public_id]), alert: error.message
  end
end
