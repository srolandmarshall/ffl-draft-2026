# frozen_string_literal: true

class Components::LeagueHistories::Show < Components::Base
  def initialize(league:, seasons:, tendencies:)
    @league = league
    @seasons = seasons
    @tendencies = tendencies
  end

  def view_template
    content_for(:title, "#{@league.name} draft history")
    header
    render Components::LeagueHistories::FinishChart.new(seasons: @seasons, tendencies: @tendencies)
    render Components::LeagueHistories::Tendencies.new(tendencies: @tendencies)
    render Components::LeagueHistories::Seasons.new(seasons: @seasons)
  end

  private

  def header
    div(class: "mb-7 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between") do
      div do
        p(class: "text-sm font-bold uppercase tracking-[.18em] text-lime-400") { "The league vault" }
        h1(class: "mt-1 text-3xl font-black sm:text-4xl") { @league.name }
        p(class: "mt-2 text-sm text-slate-400") { "#{@seasons.size} ESPN seasons · #{@seasons.sum { |season| season.draft_picks.size }} archived picks" }
      end
      a(href: root_path, class: "rounded-lg border border-white/15 px-4 py-2 text-center text-sm font-bold hover:border-lime-400") { "Draft home" }
    end
  end
end
