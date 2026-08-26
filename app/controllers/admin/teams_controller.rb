module Admin
  class TeamsController < BaseController
    before_action :set_league
    before_action :set_team, only: %i[edit update destroy archive unarchive]

    def index
      redirect_to admin_league_path(@league)
    end

    def new
      @team = @league.teams.new
    end

    def create
      @team = @league.teams.new(team_params)
      if save_team
        redirect_to admin_league_path(@league), notice: "Team added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if save_team
        redirect_to admin_league_path(@league), notice: "Team updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @team.destroy!
      redirect_to admin_league_path(@league), notice: "Team removed."
    end

    def archive
      @team.update!(archived: true)
      redirect_to admin_league_path(@league), notice: "#{@team.name} archived."
    end

    def unarchive
      @team.update!(archived: false)
      redirect_to admin_league_path(@league), notice: "#{@team.name} restored."
    end

    private

    def set_league
      @league = League.find(params[:league_id])
    end

    def set_team
      @team = @league.teams.find(params[:id])
    end

    def team_params
      params.expect(team: %i[name owner_name abbreviation])
    end

    def save_team
      Team.transaction do
        @team.update!(team_params)
        sync_team_users(@team, params.dig(:team, :emails))
      end
      true
    rescue ActiveRecord::RecordInvalid
      false
    end

    def sync_team_users(team, email_list)
      users = email_list.to_s.split(/[\s,;]+/).filter_map do |email|
        next if email.blank?

        User.find_or_create_by_any_email!(email)
      end
      team.user_ids = users.map(&:id).uniq
    end
  end
end
