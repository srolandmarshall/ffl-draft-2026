module Drafts
  class AutoDraft
    def initialize(draft)
      @draft = draft
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

    attr_reader :draft

    def next_player_for(team)
      available = draft.available_players.by_ranking.to_a
      return if available.empty?

      open_starters = RosterSlots.new(draft:, picks: draft.picks.where(team:)).call.reject(&:bench).reject(&:filled?)

      RosterSlots::STARTER_SLOTS.each_key do |position|
        slot = open_starters.find { |candidate| candidate.position == position }
        next unless slot

        player = available.find { |candidate| slot.accepts?(candidate.position) }
        return player if player
      end

      available.first
    end
  end
end
