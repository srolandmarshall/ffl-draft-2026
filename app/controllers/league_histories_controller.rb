class LeagueHistoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_league
  before_action :authorize_league!

  def show
    imported_seasons = @league.espn_seasons.includes(:draft_picks).newest_first
    @seasons = imported_seasons.select { |season| season.draft_picks.any? }
    franchises = @league.espn_franchises.joins(:team).merge(Team.active).includes(:team_seasons, draft_picks: :espn_season).to_a
    franchises.sort_by! { |franchise| [ franchise.team&.draft_order || 999, franchise.name ] }
    @tendencies = Drafts::HistoricalTendencies.new(franchises:, seasons: @seasons).call
    @tendencies.sort_by! { |tendency| [ -tendency.finishes.values.count(1), -tendency.seasons ] }
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
