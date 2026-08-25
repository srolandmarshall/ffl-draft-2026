# frozen_string_literal: true

class Components::Drafts::BoardCell < Components::Base
  def initialize(draft:, team:, overall_number:, pick: nil, elapsed_seconds: 0, next_overall_number: draft.next_overall_number)
    @draft = draft
    @team = team
    @overall_number = overall_number
    @pick = pick
    @elapsed_seconds = elapsed_seconds
    @next_overall_number = next_overall_number
  end

  def view_template
    div(
      id: dom_id,
      class: "flex h-full min-w-0 flex-col items-center justify-center rounded border px-0.5 text-center #{cell_classes}",
      title: title,
      data: { draft_board_pick: @pick.present?.to_s }
    ) do
      @pick ? drafted_cell : span(class: "text-[.45rem] text-slate-600 sm:text-[.55rem]") { "##{@overall_number}" }
    end
  end

  private

  def dom_id = "draft-#{@draft.public_id}-board-cell-#{@overall_number}"

  def title
    @pick ? "#{@pick.player.name} — #{@team.name}" : "#{@team.name}, pick #{@overall_number}"
  end

  def cell_classes
    if @pick
      position_badge_classes(@pick.player.position)
    elsif @overall_number == @next_overall_number && @draft.live?
      "border-lime-400/70 bg-lime-400/5"
    else
      "border-white/5 bg-slate-950/30"
    end
  end

  def drafted_cell
    div(class: "flex size-6 shrink-0 items-end justify-center overflow-hidden rounded-full border border-white/15 bg-slate-800 sm:size-7") do
      if @pick.player.headshot.attached?
        img(src: url_for(player_headshot(@pick.player, size: 56)), alt: "", loading: "lazy", class: "h-full w-full object-cover object-top")
      else
        span(class: "mb-1 text-[.45rem] font-black text-slate-500") { @pick.player.position }
      end
    end
    span(class: "text-[.45rem] font-bold sm:text-[.55rem]") { @pick.player.position }
    span(class: "hidden w-full truncate text-[.6rem] font-semibold sm:block lg:text-[.7rem]") { @pick.player.name }
    span(class: "font-mono text-[.45rem] font-bold tabular-nums sm:text-[.55rem] #{pick_duration_classes(@elapsed_seconds)}") { format_pick_duration(@elapsed_seconds) }
  end
end
