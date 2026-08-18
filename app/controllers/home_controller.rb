class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    drafts = if current_user.commissioner?
      Draft.all
    else
      Draft.joins(teams: :team_memberships).where(team_memberships: { user_id: current_user.id }).distinct
    end
    @drafts = drafts.includes(:league, :draft_entries).order(created_at: :desc)
  end
end
