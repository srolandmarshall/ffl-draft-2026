module Drafts
  class AutoDraft
    # Real drafters don't always take the single top-ranked player for their
    # need -- they sometimes reach for the next guy down. Weight the pick
    # toward the best-ranked player in the pool, but leave room for that
    # variance instead of a robotic, fully deterministic result.
    POOL_SIZE = 3
    POOL_WEIGHTS = [ 0.6, 0.25, 0.15 ].freeze

    def initialize(draft, random: Random.new)
      @draft = draft
      @random = random
    end

    def call
      draft.start! if draft.setup?

      until draft.complete?
        team = draft.current_team
        break unless team

        player = next_player_for(team)
        break unless player

        MakePick.new(draft:, team:, player:).call
      end
    end

    private

    attr_reader :draft, :random

    def next_player_for(team)
      available = draft.available_players.by_ranking.to_a
      return if available.empty?

      open_starters = RosterSlots.new(draft:, picks: draft.picks.where(team:)).call.reject(&:bench).reject(&:filled?)

      RosterSlots::STARTER_SLOTS.each_key do |position|
        slot = open_starters.find { |candidate| candidate.position == position }
        next unless slot

        candidates = available.select { |candidate| slot.accepts?(candidate.position) }.first(POOL_SIZE)
        player = weighted_pick(candidates)
        return player if player
      end

      weighted_pick(available.first(POOL_SIZE))
    end

    def weighted_pick(candidates)
      return candidates.first if candidates.size <= 1

      weights = POOL_WEIGHTS.first(candidates.size)
      roll = random.rand * weights.sum
      cumulative = 0.0

      candidates.each_with_index do |candidate, index|
        cumulative += weights[index]
        return candidate if roll < cumulative
      end

      candidates.last
    end
  end
end
