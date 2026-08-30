# frozen_string_literal: true

class Components::LeagueHistories::Seasons < Components::Base
  def initialize(seasons:)
    @seasons = seasons
  end

  def view_template
    if @seasons.any?
      div(data: { controller: "history-tabs" }) do
        tabs
        div { @seasons.each_with_index { |season, index| season_panel(season, index) } }
      end
    else
      div(class: "rounded-xl border border-dashed border-white/15 p-10 text-center text-slate-500") { "No completed ESPN draft history has been synced yet." }
    end
  end

  private

  def tabs
    div(class: "mb-4 flex flex-wrap gap-2", role: "tablist", aria: { label: "Draft season" }) do
      @seasons.each_with_index do |season, index|
        selected = index.zero?
        button(type: "button", role: "tab", class: "cursor-pointer rounded-lg border px-4 py-2 text-sm font-black #{selected ? 'border-lime-400 bg-lime-400 text-slate-950' : 'border-white/10 bg-slate-900 text-slate-400'}", aria: { selected: selected.to_s }, data: { history_tabs_target: "tab", year: season.season, action: "history-tabs#select" }) { season.season }
      end
    end
  end

  def season_panel(season, index)
    picks = season.draft_picks.to_a
    section(class: "overflow-hidden rounded-xl border border-white/10 bg-slate-900", role: "tabpanel", hidden: !index.zero?, data: { history_tabs_target: "panel", year: season.season }) do
      season_header(season, picks)
      render Components::LeagueHistories::SeasonResults.new(season:)
      picks.any? ? draft_board(season, picks) : no_draft
    end
  end

  def season_header(season, picks)
    div(class: "grid gap-5 p-5 sm:grid-cols-[1fr_auto] sm:items-center") do
      div do
        p(class: "text-xs font-bold uppercase tracking-[.2em] text-blue-300") { "#{season.season} season" }
        h2(class: "mt-1 text-2xl font-black") { season.name }
        p(class: "mt-1 text-xs text-slate-500") { "#{season.team_count} teams · #{season.rounds} rounds · synced #{time_ago_in_words(season.synced_at)} ago" }
      end
      first_pick(picks.first) if picks.any?
    end
  end

  def first_pick(pick)
    div(class: "rounded-lg border border-amber-400/20 bg-amber-400/10 px-4 py-3 sm:text-right") do
      p(class: "text-[.6rem] font-bold uppercase tracking-wider text-amber-300") { "First off the board" }
      p(class: "font-black") do
        plain "#{pick.player_name} "
        span(class: "text-xs text-amber-200/70") { pick.position }
      end
      p(class: "text-xs text-slate-500") { pick.team_name }
    end
  end

  def draft_board(season, picks)
    position_counts(season)
    div(class: "divide-y divide-white/5") do
      picks.group_by(&:round).sort.each { |round, round_picks| round_row(round, round_picks) }
    end
  end

  def position_counts(season)
    div(class: "flex flex-wrap gap-2 border-y border-white/5 bg-slate-950/35 px-5 py-3") do
      season.position_counts.each do |position, count|
        span(class: "rounded-full border px-2 py-1 text-[.65rem] font-bold #{position_badge_classes(position)}") { "#{position || '?'} #{count}" }
      end
    end
  end

  def round_row(round, picks)
    div(class: "grid", style: "grid-template-columns: 2rem repeat(#{picks.size}, minmax(0, 1fr))") do
      div(class: "flex min-h-14 items-center justify-center border-r border-white/10 text-[.6rem] font-black text-slate-600") { round }
      picks.sort_by(&:round_pick).each { |pick| pick_cell(pick) }
    end
  end

  def pick_cell(pick)
    div(class: "flex min-w-0 flex-col justify-center border-r border-white/5 px-1 py-2 text-center last:border-r-0 #{position_badge_classes(pick.position)}", title: "##{pick.overall_number} #{pick.player_name} — #{pick.team_name}") do
      span(class: "truncate text-[.55rem] font-black sm:text-[.65rem]") { abbreviated_player_name(pick.player_name) }
      span(class: "truncate text-[.45rem] text-slate-400 sm:text-[.55rem]") { "#{pick.team_abbreviation} · #{pick.position || '?'}" }
    end
  end

  def no_draft
    p(class: "border-t border-white/5 p-7 text-center text-sm text-slate-500") { "ESPN has no completed draft for this season yet." }
  end
end
