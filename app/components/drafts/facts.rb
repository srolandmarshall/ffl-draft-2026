# frozen_string_literal: true

class Components::Drafts::Facts < Components::Base
  def initialize(draft:, facts:)
    @draft = draft
    @facts = facts
  end

  def view_template
    turbo_frame_tag("draft-#{@draft.public_id}-facts") do
      section(class: "overflow-hidden rounded-xl border border-white/10 bg-slate-900", data: { draft_facts: true }) do
        header(class: "border-b border-white/10 bg-fuchsia-400/10 px-5 py-5") do
          p(class: "text-[.65rem] font-bold uppercase tracking-[.2em] text-fuchsia-300") { "Draft-night yearbook" }
          h2(class: "mt-1 text-2xl font-black text-white") { "Draft Facts" }
          p(class: "mt-1 max-w-2xl text-sm text-slate-400") { "The runs, reaches, reunions, and roster quirks that made this draft different." }
        end
        if @facts.any?
          div(class: "grid gap-3 p-3 sm:grid-cols-2 sm:p-5 xl:grid-cols-3") { @facts.each { |fact| fact_card(fact) } }
        else
          p(class: "p-10 text-center text-sm text-slate-500") { "There are not enough completed picks to tell this draft's story yet." }
        end
      end
    end
  end

  private

  def fact_card(fact)
    article(class: "relative overflow-hidden rounded-xl border p-4 #{fact.record ? 'border-amber-300/50 bg-amber-300/10' : 'border-white/10 bg-slate-950/45'}", data: { draft_fact: fact.type, historical: fact.historical.to_s, league_record: fact.record.to_s }) do
      div(class: "flex items-start justify-between gap-3") do
        div do
          p(class: "text-[.6rem] font-black uppercase tracking-[.18em] #{fact.record ? 'text-amber-300' : 'text-fuchsia-300'}") { fact.record ? "League record" : fact.type.to_s.humanize }
          h3(class: "mt-1 text-lg font-black text-white") { fact.title }
        end
        span(class: "shrink-0 rounded-full border border-white/10 bg-white/5 px-2.5 py-1 text-xs font-black text-slate-200") { fact.value }
      end
      p(class: "mt-3 text-sm leading-relaxed text-slate-300") { fact.text }
      p(class: "mt-3 text-[.6rem] font-bold uppercase tracking-wider text-slate-500") { "Compared with synced league history" } if fact.historical
    end
  end
end
