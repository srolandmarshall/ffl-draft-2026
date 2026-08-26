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

      open_slots = RosterSlots.new(draft:, picks: draft.picks.where(team:)).call.reject(&:filled?)
      open_starters = open_slots.reject(&:bench)

      # Best player available, rank first -- unless there's no bench slack
      # left to absorb this pick, in which case a starter need has to be
      # filled now or it never gets filled.
      candidates = if open_slots.none?(&:bench)
        available.select { |player| open_starters.any? { |slot| slot.accepts?(player.position) } }
      else
        available
      end

      weighted_pick(candidates.first(POOL_SIZE))
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
