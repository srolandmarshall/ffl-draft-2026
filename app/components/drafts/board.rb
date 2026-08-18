# frozen_string_literal: true

class Components::Drafts::Board < Components::Base
  def initialize(draft:, picks:, pick_elapsed_seconds:)
    @draft = draft
    @picks = picks
    @pick_elapsed_seconds = pick_elapsed_seconds
  end

  def view_template
    picks_by_round_and_team = @picks.index_by { |pick| [ pick.round, pick.team_id ] }
    entries = @draft.draft_entries.to_a
    board_columns = "2.25rem repeat(#{entries.size}, minmax(0, 1fr))"

    div(class: "overflow-hidden rounded-lg border border-white/10 bg-slate-900") do
      div(class: "border-b border-white/10 px-4 py-3") do
        h2(class: "font-semibold") { "Draft board" }
        p(class: "text-xs text-slate-500") { "Rounds run top to bottom. Snake rounds reverse pick order." }
      end
      div(class: "max-h-[42rem] divide-y divide-white/10 overflow-y-auto") do
        header_row(entries, board_columns)
        (1..@draft.rounds).each do |round|
          round_row(round, entries, board_columns, picks_by_round_and_team)
        end
      end
    end
  end

  private

  def header_row(entries, board_columns)
    div(class: "sticky top-0 z-10 grid bg-slate-800", style: "grid-template-columns: #{board_columns}") do
      div(class: "border-r border-white/10 px-1 py-2 text-center text-[.55rem] font-bold text-slate-500 sm:text-[.65rem]") { "RD" }
      entries.each do |entry|
        div(class: "truncate border-r border-white/10 px-0.5 py-2 text-center text-[.5rem] font-bold text-slate-300 sm:text-[.65rem]", title: entry.team.name) { entry.team.abbreviation }
      end
    end
  end

  def round_row(round, entries, board_columns, picks_by_round_and_team)
    div(class: "grid", style: "grid-template-columns: #{board_columns}", data: { draft_board_row: round }) do
      div(class: "flex min-h-14 items-center justify-center border-r border-white/10 text-[.6rem] font-bold text-slate-500 sm:min-h-16 sm:text-xs") { round }
      entries.each do |entry|
        pick_offset = @draft.snake? && round.even? ? entries.size - entry.position : entry.position - 1
        overall_number = ((round - 1) * entries.size) + pick_offset + 1
        board_cell(round, entry, overall_number, picks_by_round_and_team[[ round, entry.team_id ]])
      end
    end
  end

  def board_cell(round, entry, overall_number, pick)
    div(class: "min-w-0 border-r border-white/10 p-0.5 sm:p-1") do
      cell_class = if pick
        position_badge_classes(pick.player.position)
      elsif overall_number == @draft.next_overall_number && @draft.live?
        "border-lime-400/70 bg-lime-400/5"
      else
        "border-white/5 bg-slate-950/30"
      end
      div(class: "flex h-full min-w-0 flex-col items-center justify-center rounded border px-0.5 text-center #{cell_class}", title: pick ? "#{pick.player.name} — #{entry.team.name}" : "#{entry.team.name}, pick #{overall_number}", data: { draft_board_pick: pick.present?.to_s }) do
        pick ? drafted_cell(pick) : span(class: "text-[.45rem] text-slate-600 sm:text-[.55rem]") { "##{overall_number}" }
      end
    end
  end

  def drafted_cell(pick)
    elapsed = @pick_elapsed_seconds.fetch(pick.id) { @pick_elapsed_seconds.fetch(pick.id.to_s, 0) }
    div(class: "flex size-6 shrink-0 items-end justify-center overflow-hidden rounded-full border border-white/15 bg-slate-800 sm:size-7") do
      if pick.player.headshot.attached?
        img(src: url_for(player_headshot(pick.player, size: 56)), alt: "", loading: "lazy", class: "h-full w-full object-cover object-top")
      else
        span(class: "mb-1 text-[.45rem] font-black text-slate-500") { pick.player.position }
      end
    end
    span(class: "text-[.45rem] font-bold sm:text-[.55rem]") { pick.player.position }
    span(class: "hidden w-full truncate text-[.6rem] font-semibold sm:block lg:text-[.7rem]") { pick.player.name }
    span(class: "font-mono text-[.45rem] font-bold tabular-nums sm:text-[.55rem] #{pick_duration_classes(elapsed)}") { format_pick_duration(elapsed) }
  end
end
