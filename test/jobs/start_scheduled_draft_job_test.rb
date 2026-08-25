require "test_helper"

class StartScheduledDraftJobTest < ActiveJob::TestCase
  test "starts a setup draft once its scheduled time arrives" do
    draft = drafts(:two)
    draft.update_column(:scheduled_start_at, 1.minute.ago)

    StartScheduledDraftJob.perform_now(draft)

    assert_predicate draft.reload, :live?
    assert_in_delta Time.current, draft.started_at, 2.seconds
  end

  test "does not start a draft before its current scheduled time" do
    draft = drafts(:two)
    draft.update_column(:scheduled_start_at, 1.hour.from_now)

    StartScheduledDraftJob.perform_now(draft)

    assert_predicate draft.reload, :setup?
  end

  test "does not restart a draft that was started manually" do
    draft = drafts(:two)
    draft.update_column(:scheduled_start_at, 1.minute.ago)
    draft.start!
    started_at = draft.started_at

    travel 1.minute do
      StartScheduledDraftJob.perform_now(draft)
    end

    assert_equal started_at, draft.reload.started_at
  end
end
