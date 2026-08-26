require "test_helper"

class PrecomputeDraftFactsJobTest < ActiveSupport::TestCase
  setup do
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rails.cache = @original_cache
  end

  test "caches generated facts for a completed draft" do
    draft = drafts(:one)
    draft.update!(status: :complete, completed_at: Time.current)
    draft.picks.create!(team: teams(:one), player: players(:one), round: 1, overall_number: 1, elapsed_seconds: 12)

    PrecomputeDraftFactsJob.perform_now(draft)

    cached = Rails.cache.read(Drafts::FactGenerator.cache_key(draft))
    expected = Drafts::FactGenerator.new(draft:, picks: draft.picks.to_a).call

    assert_equal expected.map(&:title), cached.map(&:title)
  end

  test "does not cache facts for a draft that is not complete" do
    draft = drafts(:one)

    PrecomputeDraftFactsJob.perform_now(draft)

    assert_nil Rails.cache.read(Drafts::FactGenerator.cache_key(draft))
  end
end
