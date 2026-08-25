class PickTimersController < ApplicationController
  before_action :authenticate_user!

  def update
    draft = Draft.find_by!(public_id: params[:draft_public_id])
    unless current_user.commissioner?
      redirect_to root_path, alert: "Commissioner access is required."
      return
    end

    case params.require(:state)
    when "pause" then draft.pause_pick_timer!
    when "resume" then draft.resume_pick_timer!
    else raise ActionController::BadRequest, "Unknown timer state"
    end

    draft.broadcast_action_later_to(draft, action: :refresh_frame, target: "draft-#{draft.public_id}-clock", render: false)
    redirect_to draft_path(draft.public_id)
  rescue ActiveRecord::RecordInvalid
    redirect_to draft_path(params[:draft_public_id]), alert: "Only a live draft timer can be paused."
  end
end
