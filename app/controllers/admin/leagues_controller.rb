module Admin
  class LeaguesController < BaseController
    before_action :set_league, only: %i[show edit update destroy team_order]

    def index
      @leagues = League.order(season: :desc, name: :asc)
    end

    def show
      @teams = @league.teams.in_draft_order
      @drafts = @league.drafts.order(created_at: :desc)
      @espn_seasons = @league.espn_seasons.includes(:draft_picks).newest_first
      @espn_settings = DataSources::Espn::LeagueSettings.from_settings(@league.espn_settings) if @league.espn_settings.present?
    end

    def new
      @league = League.new(season: Date.current.year, roster_size: 16)
    end

    def create
      @league = League.new(league_params)
      if @league.save
        redirect_to admin_league_path(@league), notice: "League created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @league.update(league_params)
        redirect_to admin_league_path(@league), notice: "League updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @league.destroy!
      redirect_to admin_leagues_path, notice: "League deleted."
    end

    def team_order
      team_ids = Array(params[:team_ids]).map(&:to_i)
      unless team_ids.uniq.sort == @league.team_ids.sort
        redirect_to admin_league_path(@league), alert: "Draft order must include every team exactly once."
        return
      end

      Team.transaction do
        team_ids.each.with_index(1) do |team_id, position|
          @league.teams.find(team_id).update!(draft_order: position)
        end
      end
      redirect_to admin_league_path(@league)
    end

    private

    def set_league
      @league = League.find(params[:id])
    end

    def league_params
      params.expect(league: %i[name season espn_league_id qb_slots rb_slots wr_slots te_slots flex_slots k_slots dst_slots bench_slots ppr draft_type])
    end
  end
end
