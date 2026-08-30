# frozen_string_literal: true

class Components::LeagueHistories::HeadToHead < Components::Base
  def initialize(record_book:)
    @records = record_book.records
    @series = record_book.head_to_head.index_by { |matchup| pair_key(matchup.franchise_a, matchup.franchise_b) }
  end

  def view_template
    return if @series.empty?

    section(class: "mb-8", aria: { labelledby: "head-to-head-title" }) do
      p(class: "text-xs font-bold uppercase tracking-[.18em] text-cyan-300") { "Everybody remembers" }
      h2(id: "head-to-head-title", class: "mt-1 text-2xl font-black") { "Head-to-head ledger" }
      p(class: "mt-1 text-sm text-slate-400") { "Every decided matchup counts. Hover or focus a cell for regular-season, playoff, and consolation splits." }
      grid
    end
  end

  private

  def grid
    div(class: "mt-4 overflow-x-auto rounded-xl border border-white/10 bg-slate-900") do
      table(class: "min-w-max border-collapse text-center text-[.65rem]") do
        caption(class: "sr-only") { "Head-to-head wins, losses, and ties for every franchise pairing" }
        thead { header_row }
        tbody { @records.each { |record| franchise_row(record.franchise) } }
      end
    end
  end

  def header_row
    tr(class: "bg-slate-950/50") do
      th(scope: "col", class: "sticky left-0 z-20 min-w-36 bg-slate-950 px-3 py-2 text-left text-slate-500") { "Franchise" }
      @records.each do |record|
        th(scope: "col", class: "max-w-24 px-2 py-2 font-bold text-slate-400") { record.franchise.name }
      end
    end
  end

  def franchise_row(franchise)
    tr(class: "border-t border-white/5") do
      th(scope: "row", class: "sticky left-0 z-10 max-w-36 truncate bg-slate-900 px-3 py-2 text-left text-xs font-bold") { franchise.name }
      @records.each { |opponent| ledger_cell(franchise, opponent.franchise) }
    end
  end

  def ledger_cell(franchise, opponent)
    if franchise == opponent
      td(class: "bg-white/[.02] px-2 py-2 text-slate-700", aria: { label: "#{franchise.name} versus itself" }) { "—" }
      return
    end

    series = @series[pair_key(franchise, opponent)]
    unless series
      td(class: "px-2 py-2 text-slate-700", aria: { label: "No archived games between #{franchise.name} and #{opponent.name}" }) { "—" }
      return
    end

    wins, losses = series.franchise_a == franchise ? [ series.wins_a, series.wins_b ] : [ series.wins_b, series.wins_a ]
    label = "#{franchise.name} versus #{opponent.name}: #{wins} wins, #{losses} losses, #{series.ties} ties; #{series.regular_season_games} regular season, #{series.playoff_games} winners bracket, #{series.consolation_games} consolation"
    td(class: "px-2 py-2 font-bold text-slate-300", title: label, tabindex: "0", aria: { label: }) { "#{wins}-#{losses}-#{series.ties}" }
  end

  def pair_key(first, second) = [ first.id, second.id ].sort
end
