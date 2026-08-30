# frozen_string_literal: true

class Components::LeagueHistories::Show < Components::Base
  def initialize(page:)
    @page = page
    @league = page.league
  end

  def view_template
    content_for(:title, "#{@league.name} draft history")
    header
    render Components::LeagueHistories::FinishChart.new(seasons: @page.seasons, tendencies: @page.tendencies)
    render Components::LeagueHistories::RecordBook.new(record_book: @page.record_book)
    render Components::LeagueHistories::Rivalries.new(record_book: @page.record_book)
    render Components::LeagueHistories::HeadToHead.new(record_book: @page.record_book)
    render Components::LeagueHistories::Tendencies.new(tendencies: @page.tendencies)
    render Components::LeagueHistories::Seasons.new(seasons: @page.seasons)
  end

  private

  def header
    div(class: "mb-7 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between") do
      div do
        p(class: "text-sm font-bold uppercase tracking-[.18em] text-lime-400") { "The league vault" }
        h1(class: "mt-1 text-3xl font-black sm:text-4xl") { @league.name }
        p(class: "mt-2 text-sm text-slate-400") { "#{@page.seasons.size} ESPN seasons · #{@page.seasons.sum { |season| season.draft_picks.size }} archived picks" }
      end
      div(class: "flex gap-2") do
        a(href: league_story_path(@league), class: "rounded-lg border border-lime-400/60 bg-lime-400/10 px-4 py-2 text-center text-sm font-bold text-lime-300 hover:bg-lime-400/20") { "The long story" }
        a(href: root_path, class: "rounded-lg border border-white/15 px-4 py-2 text-center text-sm font-bold hover:border-lime-400") { "Draft home" }
      end
    end
  end
end
