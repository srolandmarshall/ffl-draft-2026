# frozen_string_literal: true

class Components::LeagueStories::RecordBook < Components::Base
  def initialize(superlatives:)
    @superlatives = superlatives
  end

  def view_template
    section(class: "mb-10") do
      div(class: "mb-5") do
        p(class: "text-xs font-bold uppercase tracking-[.2em] text-violet-300") { "The record book" }
        h2(class: "mt-1 text-2xl font-black sm:text-3xl") { "Extremes" }
      end
      div(class: "grid gap-5 lg:grid-cols-2") do
        panel("Highest weeks", @superlatives.highest_scores) { |entry| score_line(entry) }
        panel("Closest games", @superlatives.closest_games) { |entry| margin_line(entry) }
        panel("Biggest blowouts", @superlatives.largest_margins) { |entry| margin_line(entry) }
        panel("Shootouts", @superlatives.highest_combined) { |entry| combined_line(entry) }
      end
    end
  end

  private

  def panel(title, entries, &block)
    return if entries.blank?

    div(class: "overflow-hidden rounded-2xl border border-white/10 bg-slate-900") do
      p(class: "border-b border-white/5 px-4 py-3 text-xs font-bold uppercase tracking-[.16em] text-slate-400") { title }
      ol(class: "divide-y divide-white/5") do
        entries.first(5).each_with_index do |entry, index|
          li(class: "flex items-baseline gap-3 px-4 py-2.5") do
            span(class: "w-4 shrink-0 text-xs font-black text-slate-600") { (index + 1).to_s }
            block.call(entry)
          end
        end
      end
    end
  end

  def score_line(entry)
    span(class: "min-w-0 flex-1 text-sm") do
      span(class: "font-black tabular-nums text-lime-300") { number_with_precision(entry.points, precision: 2) }
      plain " "
      span(class: "text-slate-300") { entry.team_name.to_s }
      plain " "
      span(class: "text-slate-500") { "· #{entry.season} wk #{entry.matchup.matchup_period} vs #{entry.opponent_name}" }
    end
  end

  def margin_line(entry)
    span(class: "min-w-0 flex-1 text-sm") do
      span(class: "font-black tabular-nums text-lime-300") { number_with_precision(entry.margin, precision: 2) }
      plain " "
      span(class: "text-slate-300") { "#{entry.team_name} over #{entry.opponent_name}" }
      plain " "
      span(class: "text-slate-500") { "· #{entry.season} wk #{entry.matchup.matchup_period}" }
    end
  end

  def combined_line(entry)
    span(class: "min-w-0 flex-1 text-sm") do
      span(class: "font-black tabular-nums text-lime-300") { number_with_precision(entry.combined, precision: 2) }
      plain " "
      span(class: "text-slate-300") { "#{entry.team_name} vs #{entry.opponent_name}" }
      plain " "
      span(class: "text-slate-500") { "· #{entry.season} wk #{entry.matchup.matchup_period}" }
    end
  end
end
