class ExportsController < ApplicationController
  before_action :authenticate_user!

  def show
    draft = Draft.includes(picks: :player, draft_entries: :team).find_by!(public_id: params[:draft_public_id])
    unless current_user.commissioner? || draft.teams.joins(:team_memberships).exists?(team_memberships: { user_id: current_user.id })
      redirect_to root_path, alert: "That email is not assigned to a team in this draft."
      return
    end
    export = Drafts::Export.new(draft)

    respond_to do |format|
      format.csv { send_data export.to_csv, filename: filename(draft, "csv") }
      format.xlsx { send_data export.to_xlsx, filename: filename(draft, "xlsx") }
      format.json { render json: export.as_json }
    end
  end

  private

  def filename(draft, extension)
    "#{draft.league.name.parameterize}-#{draft.league.season}-draft.#{extension}"
  end
end
