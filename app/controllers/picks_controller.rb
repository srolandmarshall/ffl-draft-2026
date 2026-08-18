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
    redirect_to draft_path(draft.public_id), notice: "#{team.name} has picked #{player.name} (#{player.position})"
  rescue Drafts::MakePick::InvalidPick => error
    redirect_to draft_path(params[:draft_public_id]), alert: error.message
  end
end
