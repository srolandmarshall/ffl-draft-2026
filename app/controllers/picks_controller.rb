class PicksController < ApplicationController
  before_action :authenticate_user!

  def create
    draft = Draft.find_by!(public_id: params[:draft_public_id])
    if draft.complete?
      render_completed_draft(draft)
      return
    end

    team = if current_user.commissioner?
      draft.current_team
    else
      draft.teams.joins(:team_memberships).find_by(team_memberships: { user_id: current_user.id })
    end
    raise Drafts::MakePick::InvalidPick, "Your email is not assigned to a team in this draft." unless team

    player = Player.find(params.require(:player_id))
    Drafts::MakePick.new(draft:, team:, player:).call
    respond_to do |format|
      format.turbo_stream do
        if draft.complete?
          render turbo_stream: turbo_stream.action(:visit, draft_path(draft.public_id), allow_inferred_rendering: false)
        else
          # The committed pick broadcasts targeted updates to every draft viewer.
          # Re-navigating the enclosing room frame here duplicates that work and
          # causes the whole room to disappear and reflow between broadcasts.
          head :no_content
        end
      end
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
    respond_to do |format|
      format.turbo_stream do
        # The undone pick broadcasts targeted updates to every draft viewer.
        # Re-navigating the enclosing clock frame here duplicates that work and
        # races it, which is what produces the "Content missing" error.
        head :no_content
      end
      format.html { redirect_to draft_path(draft.public_id), notice: "Undid #{pick.team.name}'s pick of #{pick.player.name}. The clock is paused." }
    end
  rescue Drafts::UndoPick::InvalidUndo => error
    redirect_to draft_path(params[:draft_public_id]), alert: error.message
  end

  private

  def render_completed_draft(draft)
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.action(:visit, draft_path(draft.public_id), allow_inferred_rendering: false) }
      format.html { redirect_to draft_path(draft.public_id) }
    end
  end
end
