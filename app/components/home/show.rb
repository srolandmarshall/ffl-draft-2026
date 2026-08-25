# frozen_string_literal: true

class Components::Home::Show < Components::Base
  def initialize(drafts:)
    @drafts = drafts
  end

  def view_template
    content_for(:title, "Fantasy Draft")
    div(class: "mb-8") do
      h1(class: "text-2xl font-bold") { "Your league drafts" }
      p(class: "mt-2 text-sm text-slate-400") { "Open the room, choose your team, and try not to draft a kicker in round six." }
    end
    div(class: "overflow-hidden rounded-lg border border-white/10 bg-slate-900") do
      @drafts.each { |draft| draft_link(draft) }
      empty_state if @drafts.empty?
    end
  end

  private

  def draft_link(draft)
    a(href: draft_path(draft.public_id), class: "flex items-center justify-between gap-5 border-b border-white/10 px-5 py-4 last:border-0 hover:bg-white/5") do
      div do
        p(class: "font-semibold") { draft.name }
        p(class: "mt-1 text-sm text-slate-400") { "#{draft.league.name} · #{draft.league.season} · #{pluralize(draft.draft_entries.size, 'team')} · #{draft.rounds} rounds" }
      end
      span(class: "shrink-0 text-xs font-semibold uppercase tracking-wide text-slate-400") { "#{draft.status} →" }
    end
  end

  def empty_state
    div(class: "p-8 text-center text-sm text-slate-400") do
      plain "No draft yet. "
      a(href: admin_root_path, class: "font-semibold text-lime-400 underline") { "Set up the league" }
      plain "."
    end
  end
end
