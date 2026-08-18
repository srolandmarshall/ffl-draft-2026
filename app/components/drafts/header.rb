# frozen_string_literal: true

class Components::Drafts::Header < Components::Base
  def initialize(draft)
    @draft = draft
  end

  def view_template
    div(class: "mb-4 flex items-start justify-between gap-3 sm:mb-7 sm:items-end") do
      div(class: "min-w-0") do
        p(class: "text-sm font-bold text-lime-400") { "#{@draft.league.name} · #{@draft.league.season}" }
        h1(class: "truncate text-xl font-bold sm:text-2xl") { @draft.name }
        p(class: "mt-1 text-[.65rem] leading-relaxed text-slate-400 sm:mt-2 sm:text-xs") do
          "#{@draft.team_count} teams · #{@draft.draft_type.titleize} · #{@draft.ppr.to_f} PPR · #{@draft.roster_summary}"
        end
      end
      div(class: "shrink-0 pt-1 sm:pt-0") do
        span(class: "rounded-full border border-white/10 bg-white/5 px-2 py-1 text-[.6rem] font-semibold uppercase tracking-wide text-slate-400 sm:text-xs") do
          "Status: #{@draft.status}"
        end
      end
    end
  end
end
