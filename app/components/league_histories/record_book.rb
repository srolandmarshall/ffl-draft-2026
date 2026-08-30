# frozen_string_literal: true

class Components::LeagueHistories::RecordBook < Components::Base
  def initialize(record_book:)
    @record_book = record_book
  end

  def view_template
    return if @record_book.records.empty?

    section(class: "mb-8 overflow-hidden rounded-2xl border border-white/10 bg-slate-900", aria: { labelledby: "record-book-title" }) do
      header
      records_table
      storylines
    end
  end

  private

  def header
    div(class: "border-b border-white/5 bg-gradient-to-r from-amber-400/10 via-transparent to-lime-400/10 p-5") do
      p(class: "text-xs font-bold uppercase tracking-[.18em] text-amber-300") { "Wins, banners, heartbreak" }
      h2(id: "record-book-title", class: "mt-1 text-2xl font-black") { "The all-time record book" }
      p(class: "mt-1 text-sm text-slate-400") { "Regular-season records stay separate from the winners bracket. Historical franchises remain in the book." }
    end
  end

  def records_table
    div(class: "overflow-x-auto") do
      table(class: "min-w-[760px] w-full text-left text-xs") do
        caption(class: "sr-only") { "All-time regular-season and playoff records by franchise" }
        thead(class: "bg-slate-950/40 text-[.6rem] uppercase tracking-wider text-slate-500") do
          tr do
            %w[Franchise Seasons Record Win% PF PA Playoffs Titles Runner-up Top seeds].each do |label|
              th(scope: "col", class: "whitespace-nowrap px-3 py-2 first:pl-5 last:pr-5") { label }
            end
          end
        end
        tbody(class: "divide-y divide-white/5") do
          @record_book.records.each { |record| record_row(record) }
        end
      end
    end
  end

  def record_row(record)
    tr do
      th(scope: "row", class: "whitespace-nowrap px-3 py-3 pl-5 text-sm font-bold") { record.franchise.name }
      td(class: cell_classes) { record.seasons }
      td(class: cell_classes) { "#{record.wins}-#{record.losses}-#{record.ties}" }
      td(class: cell_classes) { Kernel.format("%.3f", record.win_pct).delete_prefix("0") }
      td(class: cell_classes) { number_with_precision(record.points_for, precision: 1, delimiter: ",") }
      td(class: cell_classes) { number_with_precision(record.points_against, precision: 1, delimiter: ",") }
      td(class: cell_classes) { record.playoff_appearances }
      td(class: "#{cell_classes} font-black text-amber-300") { record.championships }
      td(class: cell_classes) { record.runner_ups }
      td(class: "#{cell_classes} pr-5") { record.regular_season_titles }
    end
  end

  def cell_classes = "whitespace-nowrap px-3 py-3 text-slate-300"

  def storylines
    div(class: "grid gap-3 border-t border-white/5 p-5 md:grid-cols-3") do
      championship_story
      dynasty_story
      correction_story
    end
  end

  def championship_story
    outcomes = @record_book.championship_outcomes
    unless outcomes.any?
      story_card("Top seed held serve", "Not archived", "No completed winners bracket is available", "text-lime-300")
      return
    end

    held = outcomes.count(&:same_franchise?)
    story_card("Top seed held serve", "#{held} of #{outcomes.size}", "regular-season champions also won the bracket", "text-lime-300")
  end

  def dynasty_story
    arc = @record_book.dynasties.first
    if arc
      value = "#{arc.start_season}–#{arc.end_season}"
      detail = "#{arc.franchise.name}: #{arc.playoff_appearances} straight playoffs, #{arc.championships} titles"
      story_card("Top playoff run", value, detail, "text-violet-300")
    else
      story_card("Top playoff run", "Not yet", "No consecutive playoff run is archived", "text-violet-300")
    end
  end

  def correction_story
    delta = @record_book.consolation_deltas.first
    if delta
      detail = "#{delta.franchise.name} was #{delta.regular_season_rank.ordinalize} in #{delta.season}, not ESPN's consolation-adjusted #{delta.espn_final_rank.ordinalize}"
      story_card("Finish audit", "#{@record_book.consolation_deltas.size} corrected", detail, "text-cyan-300")
    else
      story_card("Finish audit", "No deltas", "Archived ESPN ranks match the canonical standings", "text-cyan-300")
    end
  end

  def story_card(label, value, detail, color)
    article(class: "rounded-xl border border-white/5 bg-slate-950/40 p-4") do
      p(class: "text-[.6rem] font-bold uppercase tracking-wider #{color}") { label }
      strong(class: "mt-1 block text-xl") { value }
      p(class: "mt-1 text-xs leading-relaxed text-slate-500") { detail }
    end
  end
end
