# frozen_string_literal: true

class Components::Drafts::Board < Components::Base
  def initialize(draft:, picks:, pick_elapsed_seconds:, selected_team: nil)
    @draft = draft
    @picks = picks
    @pick_elapsed_seconds = pick_elapsed_seconds
    @selected_team_id = selected_team&.id
  end

  def view_template
    picks_by_round_and_team = @picks.index_by { |pick| [ pick.round, pick.team_id ] }
    @next_overall_number = @picks.size + 1
    entries = @draft.draft_entries.to_a
    board_columns = "3rem repeat(#{entries.size}, minmax(0, 1fr))"

    div(id: "draft-#{@draft.public_id}-board-content", class: "overflow-hidden rounded-lg border border-white/10 bg-slate-900") do
      div(class: "border-b border-white/10 px-4 py-3") do
        h2(class: "font-semibold") { "Draft board" }
      end
      div(class: "divide-y divide-white/10") do
        header_row(entries, board_columns)
        (1..@draft.rounds).each do |round|
          round_row(round, entries, board_columns, picks_by_round_and_team)
        end
      end
    end
  end

  private

  def header_row(entries, board_columns)
    div(class: "sticky top-0 z-10 hidden bg-slate-800 min-[900px]:grid", style: "grid-template-columns: #{board_columns}") do
      div(class: "border-r border-white/10 px-1 py-3 text-center text-xs font-bold text-slate-500") { "RD" }
      entries.each do |entry|
        div(
          class: "border-r px-1 py-3 text-center text-xs font-bold leading-tight #{team_column_classes(entry.team_id, header: true)}",
          title: entry.team.name,
          aria: { label: entry.team_id == @selected_team_id ? "#{entry.team.name}, your team" : entry.team.name }
        ) { entry.team.abbreviation }
      end
    end
  end

  def round_row(round, entries, board_columns, picks_by_round_and_team)
    div(class: "flex flex-col divide-y divide-white/5 min-[900px]:grid min-[900px]:divide-y-0", style: "grid-template-columns: #{board_columns}", data: { draft_board_row: round }) do
      div(class: "flex items-center whitespace-nowrap border-white/10 px-2 py-1 text-[.6rem] font-bold uppercase tracking-wide text-slate-500 min-[900px]:min-h-24 min-[900px]:justify-center min-[900px]:border-r min-[900px]:px-1 min-[900px]:py-0 min-[900px]:text-sm min-[900px]:normal-case min-[900px]:tracking-normal") { "R#{round}" }
      entries.each do |entry|
        pick_offset = @draft.snake? && round.even? ? entries.size - entry.position : entry.position - 1
        overall_number = ((round - 1) * entries.size) + pick_offset + 1
        board_cell(round, entry, overall_number, picks_by_round_and_team[[ round, entry.team_id ]])
      end
    end
  end

  def board_cell(round, entry, overall_number, pick)
    pick_in_round = ((overall_number - 1) % @draft.draft_entries.size) + 1
    div(
      class: "order-[var(--mobile-order)] min-w-0 border-white/10 py-0.5 min-[900px]:order-none min-[900px]:border-r min-[900px]:p-1.5 #{team_column_classes(entry.team_id)}",
      style: "--mobile-order: #{pick_in_round}",
      data: { draft_board_team_id: entry.team_id }
    ) do
      render Components::Drafts::BoardCell.new(
        draft: @draft,
        team: entry.team,
        overall_number:,
        pick:,
        elapsed_seconds: elapsed_seconds_for(pick),
        next_overall_number: @next_overall_number
      )
    end
  end

  def elapsed_seconds_for(pick)
    return 0 unless pick

    @pick_elapsed_seconds.fetch(pick.id) { @pick_elapsed_seconds.fetch(pick.id.to_s, 0) }
  end

  def team_column_classes(team_id, header: false)
    return "border-white/10 #{header ? "text-slate-300" : nil}" unless team_id == @selected_team_id

    if header
      "border-lime-300/60 bg-lime-300 text-slate-950 ring-1 ring-inset ring-lime-100"
    else
      "border-lime-300/40 bg-lime-300/10 ring-1 ring-inset ring-lime-300/20"
    end
  end
end
