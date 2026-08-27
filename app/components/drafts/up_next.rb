# frozen_string_literal: true

class Components::Drafts::UpNext < Components::Base
  COLUMN_CLASSES = {
    1 => "grid-cols-1",
    2 => "grid-cols-2",
    3 => "grid-cols-3"
  }.freeze

  def initialize(draft:)
    @draft = draft
  end

  def view_template
    return unless @draft.live?

    picks = @draft.upcoming_picks(3)
    return if picks.empty?

    section(class: "w-full overflow-hidden rounded-xl border border-white/10 bg-slate-900") do
      p(class: "border-b border-white/10 px-3 py-1.5 text-[.65rem] font-bold uppercase tracking-wider text-slate-400") { "Up next" }
      div(class: "grid min-w-0 #{COLUMN_CLASSES.fetch(picks.size)} divide-x divide-white/5") do
        picks.each_with_index { |pick, index| pick_column(pick, index) }
      end
    end
  end

  private

  def pick_column(pick, index)
    div(class: "min-w-0 px-3 py-2") do
      span(class: "flex items-center gap-1.5 text-[.6rem] font-bold uppercase tracking-wide text-slate-500") do
        span(class: "flex size-4 shrink-0 items-center justify-center rounded-full bg-white/10 text-[.55rem] text-slate-300") { (index + 1).to_s }
        span(class: "truncate") { "Round #{pick.round}, Pick #{pick.pick_in_round} (#{pick.overall_number})" }
      end
      span(class: "mt-1 block truncate text-sm font-bold text-slate-100") { pick.team.name }
    end
  end
end
