module Admin
  class DraftsController < BaseController
    before_action :set_league
    before_action :set_draft, only: %i[edit update destroy start restart]

    def index
      redirect_to admin_league_path(@league)
    end

    def new
      count = @league.teams.size.in?(2..20) ? @league.teams.size : 10
      @draft = @league.drafts.new(name: "#{@league.season} Draft", team_count: count)
      @draft.assign_attributes(@league.draft_defaults)
    end

    def create
      @draft = @league.drafts.new(draft_params)
      if save_with_entries
        redirect_to admin_league_path(@league), notice: "Draft created with #{@draft.draft_entries.size} teams."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @draft.setup? && update_draft_and_order
        redirect_to admin_league_path(@league), notice: "Draft updated."
      else
        @draft.errors.add(:base, "A live draft cannot be edited") unless @draft.setup?
        render :edit, status: :unprocessable_entity
      end
    end

    def start
      @draft.start!
      redirect_to draft_path(@draft.public_id), notice: "The draft is live. Share this page with your league."
    end

    def restart
      Draft.transaction do
        @draft.picks.delete_all
        @draft.update!(status: :live, started_at: Time.current, pick_timer_paused_at: nil, pick_timer_paused_seconds: 0)
      end
      redirect_to draft_path(@draft.public_id), notice: "The draft was restarted."
    end

    def destroy
      @draft.destroy!
      redirect_to admin_league_path(@league), notice: "Draft deleted."
    end

    private

    def set_league
      @league = League.find(params[:league_id])
    end

    def set_draft
      @draft = @league.drafts.find(params[:id])
    end

    def draft_params
      params.expect(draft: %i[name team_count qb_slots rb_slots wr_slots te_slots flex_slots k_slots dst_slots bench_slots ppr draft_type])
    end

    def save_with_entries
      Draft.transaction do
        @draft.assign_attributes(draft_params)
        teams = configured_teams
        @draft.save!
        teams.each.with_index(1) do |team, position|
          @draft.draft_entries.create!(team:, position:)
        end
        @league.update!(roster_size: @draft.roster_size)
      end
      true
    rescue ActiveRecord::RecordInvalid => error
      copy_nested_errors(error)
      false
    end

    def update_draft_and_order
      Draft.transaction do
        @draft.assign_attributes(draft_params)
        teams = configured_teams
        @draft.save!
        @draft.draft_entries.delete_all
        teams.each.with_index(1) do |team, position|
          @draft.draft_entries.create!(team:, position:)
        end
        @league.update!(roster_size: @draft.roster_size)
      end
      true
    rescue ActiveRecord::RecordInvalid => error
      copy_nested_errors(error)
      false
    end

    def configured_teams
      count = draft_params[:team_count].to_i
      team_slots.first(count).map.with_index(1) do |slot, position|
        team = slot[:id].present? ? @league.teams.find(slot[:id]) : @league.teams.new
        team.update!(
          name: slot[:name].presence || "Team #{position}",
          owner_name: slot[:owner_name].presence || "Owner #{position}",
          abbreviation: slot[:abbreviation].presence || format("T%02d", position)
        )
        sync_team_users(team, slot[:emails])
        team
      end
    end

    def team_slots
      params.require(:draft).permit(team_slots: {})[:team_slots].values
        .map { |slot| slot.permit(:id, :name, :owner_name, :abbreviation, :emails) }
    end

    def sync_team_users(team, email_list)
      users = email_list.to_s.split(/[\s,;]+/).filter_map do |email|
        User.find_or_create_by_any_email!(email) if email.present?
      end
      if users.empty?
        team.errors.add(:base, "#{team.name} needs at least one email")
        raise ActiveRecord::RecordInvalid, team
      end
      team.user_ids = users.map(&:id).uniq
    end

    def copy_nested_errors(error)
      return if error.record == @draft

      @draft.errors.add(:base, error.record.errors.full_messages.to_sentence)
    end
  end
end
