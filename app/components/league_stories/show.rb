# frozen_string_literal: true

class Components::LeagueStories::Show < Components::Base
  def initialize(page:)
    @page = page
    @league = page.league
  end

  def view_template
    content_for(:title, "#{@league.name} league story")
    header
    if @page.dossiers.any?
      render Components::LeagueStories::Ledger.new(seasons: @page.seasons)
      render Components::LeagueStories::Dossiers.new(dossiers: @page.dossiers, span: @page.span)
      render Components::LeagueStories::RecordBook.new(superlatives: @page.superlatives)
      render Components::LeagueStories::DraftArchaeology.new(draft_value: @page.draft_value)
    else
      empty_state
    end
  end

  private

  def header
    div(class: "mb-8 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between") do
      div do
        p(class: "text-sm font-bold uppercase tracking-[.18em] text-lime-400") { "The long story" }
        h1(class: "mt-1 text-3xl font-black sm:text-4xl") { @league.name }
        p(class: "mt-2 text-sm text-slate-400") { subtitle }
      end
      div(class: "flex gap-2") do
        a(href: league_history_path(@league), class: "rounded-lg border border-white/15 px-4 py-2 text-center text-sm font-bold hover:border-lime-400") { "Draft history" }
        a(href: root_path, class: "rounded-lg border border-white/15 px-4 py-2 text-center text-sm font-bold hover:border-lime-400") { "Draft home" }
      end
    end
  end

  def subtitle
    return "No ESPN history has been synced yet." if @page.span.compact.empty?

    "#{@page.span.first}–#{@page.span.last} · #{pluralize(@page.dossiers.size, 'active franchise')} · #{pluralize(@page.seasons.size, 'completed season')}"
  end

  def empty_state
    div(class: "rounded-xl border border-dashed border-white/15 p-10 text-center text-slate-500") do
      "Sync ESPN league history to unlock the story."
    end
  end
end
