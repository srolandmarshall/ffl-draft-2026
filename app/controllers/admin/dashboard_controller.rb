module Admin
  class DashboardController < BaseController
    def show
      @leagues = League.includes(:teams, :drafts).order(season: :desc, name: :asc)
    end
  end
end
