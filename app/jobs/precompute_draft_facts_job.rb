class PrecomputeDraftFactsJob < ApplicationJob
  queue_as :default

  def perform(draft)
    return unless draft.complete?

    picks = draft.picks.includes(:team, :player).to_a
    facts = Drafts::FactGenerator.new(draft: draft, picks: picks).call
    Rails.cache.write(Drafts::FactGenerator.cache_key(draft), facts)
  end
end
