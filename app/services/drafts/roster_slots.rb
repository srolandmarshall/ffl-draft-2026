# frozen_string_literal: true

class Drafts::RosterSlots
  Slot = Struct.new(:label, :position, :pick, :bench, keyword_init: true) do
    def accepts?(player_position)
      position == player_position || (position == "FLEX" && %w[RB WR TE].include?(player_position))
    end

    def filled? = pick.present?
  end

  STARTER_SLOTS = {
    "QB" => :qb_slots,
    "RB" => :rb_slots,
    "WR" => :wr_slots,
    "TE" => :te_slots,
    "FLEX" => :flex_slots,
    "K" => :k_slots,
    "DST" => :dst_slots
  }.freeze

  def initialize(draft:, picks:)
    @draft = draft
    @picks = picks.sort_by(&:overall_number)
  end

  def call
    slots = starter_slots + bench_slots
    @picks.each { |pick| assign(pick, slots) }
    slots
  end

  private

  def starter_slots
    STARTER_SLOTS.flat_map do |position, attribute|
      count = @draft.public_send(attribute)
      count.times.map do |index|
        Slot.new(label: slot_label(position, index, count), position:, bench: false)
      end
    end
  end

  def bench_slots
    @draft.bench_slots.times.map do |index|
      Slot.new(label: "BN #{index + 1}", position: "BN", bench: true)
    end
  end

  def slot_label(position, index, count)
    label = position == "DST" ? "D/ST" : position
    count == 1 ? label : "#{label} #{index + 1}"
  end

  def assign(pick, slots)
    slot = slots.find { |candidate| !candidate.bench && !candidate.filled? && candidate.accepts?(pick.player.position) }
    slot ||= slots.find { |candidate| candidate.bench && !candidate.filled? }
    slot ||= overflow_bench(slots)
    slot.pick = pick
  end

  def overflow_bench(slots)
    slot = Slot.new(label: "BN #{slots.count(&:bench) + 1}", position: "BN", bench: true)
    slots << slot
    slot
  end
end
