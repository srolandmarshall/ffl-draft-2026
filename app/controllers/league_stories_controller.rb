class LeagueStoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_league
  before_action :authorize_league!

  def show
    @page = LeagueStoryPage.build(@league)
  end

  private

  def set_league
    @league = League.find(params[:id])
  end

  def authorize_league!
    return if current_user.commissioner?
    return if @league.teams.joins(:team_memberships).exists?(team_memberships: { user_id: current_user.id })

    redirect_to root_path, alert: "That email is not assigned to a team in this league."
  end
end
