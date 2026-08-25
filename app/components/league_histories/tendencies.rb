# frozen_string_literal: true

class Components::LeagueHistories::Tendencies < Components::Base
  def initialize(tendencies:)
    @tendencies = tendencies
  end

  def view_template
    return if @tendencies.empty?

    section(class: "mb-8") do
      header
      div(class: "grid gap-4 lg:grid-cols-2") { @tendencies.each { |tendency| card(tendency) } }
    end
  end

  private

  def header
    div(class: "mb-5") do
      p(class: "text-xs font-bold uppercase tracking-[.18em] text-violet-300") { "Draft fingerprints" }
      h2(class: "text-2xl font-black") { "Every team leaves a pattern" }
      p(class: "mt-1 max-w-3xl text-sm text-slate-400") { "Each ring is one round across every available draft. Split colors expose indecision; a solid ring means they keep going back to the same position." }
      div(class: "mt-3 flex flex-wrap gap-3") do
        ApplicationHelper::POSITION_CHART_COLORS.each do |position, color|
          span(class: "flex items-center gap-1.5 text-[.65rem] font-bold text-slate-400") do
            i(class: "size-2.5 rounded-full", style: "background: #{color}")
            plain position
          end
        end
      end
    end
  end

  def card(tendency)
    opening_counts = tendency.round_position_counts[1] || {}
    opening_position, opening_count = opening_counts.first
    article(class: "flex min-w-0 flex-col overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-slate-900 to-slate-950 shadow-lg shadow-black/10") do
      div(class: "p-4 sm:p-5") do
        card_header(tendency, opening_position, opening_count, opening_counts)
        highlights(tendency)
        round_rings(tendency)
      end
      card_footer(tendency)
    end
  end

  def card_header(tendency, opening_position, opening_count, opening_counts)
    div(class: "flex items-start justify-between gap-3") do
      div(class: "min-w-0") do
        p(class: "truncate text-lg font-black") { tendency.franchise.team.name }
        p(class: "mt-0.5 text-[.65rem] text-slate-500") { "#{tendency.seasons} drafts · #{tendency.pick_count} picks" }
      end
      if opening_position
        p(class: "shrink-0 text-xs text-slate-400") do
          plain "Opens "
          strong(class: "#{position_badge_classes(opening_position)} rounded-full border px-2 py-1") { "#{opening_position} #{opening_count}/#{opening_counts.values.sum}" }
        end
      end
    end
  end

  def highlights(tendency)
    div(class: "mt-4 grid grid-cols-3 gap-2") do
      highlight("Signature", "text-violet-300") do
        if tendency.signature_round
          plain "R#{tendency.signature_round.round} · #{tendency.signature_round.position} "
          span(class: "text-slate-500") { "#{tendency.signature_round.count}/#{tendency.signature_round.total}" }
        else
          plain "—"
        end
      end
      highlight("Chaos round", "text-cyan-300") { tendency.chaos_round ? "R#{tendency.chaos_round.round} · #{tendency.chaos_round.position_count} positions" : "—" }
      highlight("Biggest binge", "text-pink-300") do
        if tendency.longest_position_run
          plain "#{tendency.longest_position_run.position} ×#{tendency.longest_position_run.length} "
          span(class: "text-slate-500") { "’#{tendency.longest_position_run.season.to_s.last(2)}" }
        else
          plain "—"
        end
      end
    end
  end

  def highlight(label, color, &block)
    div(class: "rounded-lg border border-white/5 bg-slate-950/45 p-2.5") do
      span(class: "block text-[.5rem] font-bold uppercase tracking-wider #{color}") { label }
      strong(class: "mt-1 block text-xs", &block)
    end
  end

  def round_rings(tendency)
    div(class: "mt-5 grid grid-cols-8 gap-x-2 gap-y-3") do
      tendency.round_position_counts.each do |round, counts|
        position, count = counts.first
        div(class: "group min-w-0 text-center", title: "Round #{round}: #{counts.map { |label, total| "#{label} #{total}" }.join(' · ')}", data: { round: }) do
          span(class: "mb-1 block text-[.5rem] font-black uppercase tracking-wider text-slate-600") { "R#{round}" }
          div(class: "relative mx-auto aspect-square w-full max-w-11 rounded-full shadow-md shadow-black/30 transition group-hover:scale-110", style: "background: #{position_conic_gradient(counts)}") do
            div(class: "absolute inset-[3px] flex items-center justify-center rounded-full bg-slate-950/95") { strong(class: "text-[.65rem] text-white") { position || "?" } }
          end
          span(class: "mt-1 block text-[.48rem] text-slate-600") { "#{count}/#{counts.values.sum}" }
        end
      end
    end
  end

  def card_footer(tendency)
    div(class: "mt-auto flex flex-col gap-3 border-t border-white/5 bg-black/10 px-4 py-3 sm:flex-row sm:items-center sm:justify-between sm:px-5") do
      div(class: "flex flex-wrap gap-x-4 gap-y-1 text-[.65rem] text-slate-500") do
        { "QB arrives" => "QB", "TE arrives" => "TE", "Defense arrives" => "DST" }.each do |label, position|
          next unless (round = tendency.average_first_rounds[position])

          span do
            plain "#{label} "
            strong(class: "text-slate-200") { "R#{round}" }
          end
        end
      end
      return unless tendency.repeat_player_name

      div(class: "shrink-0 text-xs") do
        span(class: "font-bold uppercase tracking-wider text-lime-400") { "Loyalty:" }
        plain " "
        strong { tendency.repeat_player_name }
        span(class: "text-lime-300") { " ×#{tendency.repeat_player_count}" }
      end
    end
  end
end
