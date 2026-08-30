# frozen_string_literal: true

class Components::LeagueHistories::Rivalries < Components::Base
  def initialize(record_book:)
    @rivalries = record_book.rivalries
  end

  def view_template
    return if @rivalries.empty?

    section(class: "mb-8", aria: { labelledby: "rivalries-title" }) do
      p(class: "text-xs font-bold uppercase tracking-[.18em] text-pink-300") { "Familiar enemies" }
      h2(id: "rivalries-title", class: "mt-1 text-2xl font-black") { "The rivalries" }
      div(class: "mt-4 grid gap-3 md:grid-cols-2 xl:grid-cols-5") do
        @rivalries.each_with_index { |series, index| rivalry(series, index) }
      end
    end
  end

  private

  def rivalry(series, index)
    article(class: "rounded-xl border border-white/10 bg-slate-900 p-4") do
      p(class: "text-[.6rem] font-black uppercase tracking-wider text-pink-300") { "Rivalry ##{index + 1}" }
      h3(class: "mt-1 font-black") { "#{series.franchise_a.name} vs #{series.franchise_b.name}" }
      p(class: "mt-3 text-2xl font-black") { "#{series.wins_a}–#{series.wins_b}–#{series.ties}" }
      p(class: "mt-1 text-xs text-slate-500") { "#{series.games} games · #{series.playoff_games} playoff · #{series.consolation_games} consolation" }
      p(class: "mt-2 text-[.65rem] text-slate-600") { "Closest #{number_with_precision(series.closest_margin, precision: 1)} pts · biggest #{number_with_precision(series.largest_margin, precision: 1)}" }
    end
  end
end
