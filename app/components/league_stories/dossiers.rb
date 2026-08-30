# frozen_string_literal: true

class Components::LeagueStories::Dossiers < Components::Base
  # Tiering decides how much room a franchise gets. Champions earn the wide card.
  def initialize(dossiers:, span:)
    @dossiers = dossiers
    @span = span
  end

  def view_template
    section(class: "mb-10") do
      heading
      div(class: "grid gap-5") do
        @dossiers.each_with_index { |dossier, index| card(dossier, index) }
      end
    end
  end

  private

  def heading
    div(class: "mb-5") do
      p(class: "text-xs font-bold uppercase tracking-[.2em] text-lime-400") { "The twelve" }
      h2(class: "mt-1 text-2xl font-black sm:text-3xl") { "Who you are playing against" }
      p(class: "mt-2 max-w-3xl text-sm text-slate-400") do
        "Every franchise on this year's board, ranked by hardware. Records span #{@span.first}–#{@span.last} and count the regular season and playoffs together."
      end
    end
  end

  def card(dossier, index)
    article(class: "overflow-hidden rounded-2xl border #{border_for(dossier)} bg-slate-900 shadow-xl shadow-black/20") do
      div(class: "flex flex-col gap-4 border-b border-white/5 #{banner_for(dossier)} p-5 sm:flex-row sm:items-center sm:justify-between") do
        identity(dossier, index)
        trophies(dossier)
      end
      div(class: "grid gap-5 p-5 lg:grid-cols-[minmax(0,2fr)_minmax(0,3fr)]") do
        div do
          stat_grid(dossier)
          finish_strip(dossier)
        end
        notes(dossier)
      end
    end
  end

  def identity(dossier, index)
    div(class: "min-w-0") do
      p(class: "text-xs font-bold uppercase tracking-[.18em] #{accent_for(dossier)}") { rank_label(dossier, index) }
      h3(class: "mt-1 truncate text-2xl font-black") { dossier.name }
      p(class: "mt-1 text-xs text-slate-500") do
        parts = [ dossier.owner, pluralize(dossier.seasons, "season") ].compact_blank
        parts.join(" · ")
      end
    end
  end

  def trophies(dossier)
    div(class: "flex shrink-0 items-center gap-4") do
      if dossier.titles.positive?
        div(class: "text-right") do
          p(class: "text-3xl font-black text-amber-300") { "🏆 " + dossier.titles.to_s }
          p(class: "text-xs font-bold uppercase tracking-wider text-amber-200/70") { dossier.championship_seasons.join(", ") }
        end
      elsif dossier.runner_ups.positive?
        div(class: "text-right") do
          p(class: "text-2xl font-black text-slate-300") { "#{dossier.runner_ups}×" }
          p(class: "text-xs font-bold uppercase tracking-wider text-slate-500") { "runner-up" }
        end
      else
        p(class: "text-xs font-bold uppercase tracking-wider text-slate-600") { "still looking" }
      end
    end
  end

  def stat_grid(dossier)
    div(class: "grid grid-cols-2 gap-3 sm:grid-cols-4") do
      stat_tile("Record", "#{dossier.record.wins}-#{dossier.record.losses}")
      stat_tile("Win rate", number_with_precision(dossier.record.win_pct, precision: 3).delete_prefix("0"))
      stat_tile("Playoffs", "#{dossier.playoff_berths}/#{dossier.seasons}")
      stat_tile("Avg finish", number_with_precision(dossier.average_finish, precision: 1) || "—")
    end
  end

  def stat_tile(label, value)
    div(class: "rounded-lg border border-white/5 bg-slate-950/60 px-3 py-2") do
      p(class: "text-[10px] font-bold uppercase tracking-[.14em] text-slate-500") { label }
      p(class: "mt-0.5 text-lg font-black tabular-nums") { value }
    end
  end

  # One block per season, coloured by how the year ended.
  def finish_strip(dossier)
    div(class: "mt-4") do
      p(class: "mb-2 text-[10px] font-bold uppercase tracking-[.14em] text-slate-500") { "Season by season" }
      div(class: "flex flex-wrap gap-1.5") do
        dossier.team_seasons.each { |team_season| finish_block(team_season) }
      end
    end
  end

  def finish_block(team_season)
    div(
      class: "flex w-11 flex-col items-center rounded-md border px-1 py-1 #{finish_classes(team_season)}",
      title: "#{team_season.espn_season.season}: #{team_season.record}, #{team_season.playoff_result_label}"
    ) do
      span(class: "text-[10px] font-bold leading-none opacity-70") { team_season.espn_season.season.to_s.last(2) }
      span(class: "mt-0.5 text-sm font-black leading-none tabular-nums") { team_season.regular_season_rank.to_s }
    end
  end

  def finish_classes(team_season)
    case team_season.playoff_finish
    when 1 then "border-amber-300/60 bg-amber-300/20 text-amber-200"
    when 2 then "border-slate-300/40 bg-slate-300/10 text-slate-200"
    when 3, 5 then "border-lime-400/30 bg-lime-400/10 text-lime-200"
    else "border-white/5 bg-slate-950/60 text-slate-500"
    end
  end

  def notes(dossier)
    ul(class: "grid gap-2 text-sm") do
      note_row("Signature week", signature_week(dossier))
      note_row("Best pick", pick_line(dossier.best_pick))
      note_row("Worst pick", pick_line(dossier.worst_pick))
      note_row("Owns", series_line(dossier.prey))
      note_row("Owned by", series_line(dossier.nemesis))
      note_row("Drought", drought_line(dossier))
    end
  end

  def note_row(label, value)
    return if value.blank?

    li(class: "flex gap-3 rounded-lg bg-slate-950/40 px-3 py-2") do
      span(class: "w-24 shrink-0 text-[10px] font-bold uppercase tracking-[.14em] text-slate-500") { label }
      span(class: "min-w-0 flex-1 text-slate-300") { value }
    end
  end

  def signature_week(dossier)
    entry = dossier.best_week
    return if entry.blank?

    "#{number_with_precision(entry.points, precision: 2)} in #{entry.season}, week #{entry.matchup.matchup_period}, against #{entry.opponent_name}"
  end

  def pick_line(pick)
    return if pick.blank?

    swing = pick.value_over_draft
    direction = swing.to_i.positive? ? "gained" : "lost"
    "#{pick.player_name} (#{pick.season}, pick #{pick.overall_pick}) — drafted as #{pick.position}#{pick.position_draft_rank}, finished #{pick.position}#{pick.position_rank}, #{direction} #{swing.abs} spots"
  end

  def series_line(series)
    return if series.blank?

    "#{series.opponent.name}, #{series.record} in #{pluralize(series.games, 'meeting')}"
  end

  def drought_line(dossier)
    return "In the playoffs last season" if dossier.current_drought.zero?

    "#{pluralize(dossier.current_drought, 'season')} since the last playoff berth"
  end

  def rank_label(dossier, index)
    return "#{dossier.titles}-time champion" if dossier.titles.positive?
    return "Runner-up, never champion" if dossier.runner_ups.positive?

    "##{index + 1} by the numbers"
  end

  def border_for(dossier)
    dossier.titles.positive? ? "border-amber-300/30" : "border-white/10"
  end

  def banner_for(dossier)
    if dossier.titles.positive?
      "bg-gradient-to-r from-amber-300/15 via-transparent to-transparent"
    elsif dossier.runner_ups.positive?
      "bg-gradient-to-r from-slate-400/10 via-transparent to-transparent"
    else
      ""
    end
  end

  def accent_for(dossier)
    dossier.titles.positive? ? "text-amber-300" : "text-slate-400"
  end
end
