class StartScheduledDraftJob < ApplicationJob
  queue_as :default

  def perform(draft)
    draft.with_lock do
      return unless draft.setup? && draft.scheduled_start_at.present? && draft.scheduled_start_at <= Time.current

      draft.start!
    end

    draft.broadcast_action_to(
      draft,
      action: :visit,
      target: Rails.application.routes.url_helpers.draft_path(draft.public_id),
      render: false
    )
  end
end
