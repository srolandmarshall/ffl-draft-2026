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
      class: "relative flex min-w-0 items-center rounded border px-2 py-1 text-left min-[900px]:h-full min-[900px]:flex-col min-[900px]:justify-center min-[900px]:px-1 min-[900px]:py-2 min-[900px]:text-center #{cell_classes}",
      title: title,
      data: { draft_board_pick: @pick.present?.to_s }
    ) do
      span(class: "absolute left-1.5 top-1.5 hidden font-mono text-[.55rem] font-bold tabular-nums text-slate-500 min-[900px]:block") { pick_label }
      if @pick
        mobile_drafted_cell
        desktop_drafted_cell
      else
        mobile_empty_cell
      end
    end
  end

  private

  def dom_id = "draft-#{@draft.public_id}-board-cell-#{@overall_number}"

  def title
    if @pick
      "#{@pick.player.name} — #{@pick.player.pro_team} — #{@team.name} — Pick time #{format_pick_duration(@elapsed_seconds)}"
    else
      "#{@team.name}, pick #{pick_label}"
    end
  end

  def cell_classes
    if @pick
      position_surface_classes(@pick.player.position)
    elsif @overall_number == @next_overall_number && @draft.live?
      "border-lime-400/70 bg-lime-400/5"
    else
      "border-white/5 bg-slate-950/30"
    end
  end

  def mobile_drafted_cell
    div(class: "grid w-full min-w-0 grid-cols-[2rem_2.75rem_4.25rem_minmax(0,1fr)] items-center gap-2 min-[900px]:hidden", data: { mobile_draft_pick: @overall_number }) do
      span(class: "font-mono text-[.65rem] font-bold tabular-nums text-slate-500") { pick_label }
      span(class: "text-[.65rem] font-black text-slate-300") { @team.abbreviation }
      div(class: "flex items-center justify-center gap-0.5") do
        div(class: "flex items-end justify-center overflow-hidden rounded border border-white/15 #{mobile_portrait_size_classes} #{portrait_background_classes}") do
          if @pick.player.position == "DST"
            img(src: nfl_team_logo_url(@pick.player.pro_team), alt: "", title: @pick.player.pro_team, loading: "lazy", class: "h-full w-full object-contain p-0.5")
          elsif @pick.player.headshot.attached?
            img(src: url_for(player_headshot(@pick.player, size: 40)), alt: "", loading: "lazy", class: "h-full w-full object-cover object-top")
          else
            span(class: "text-[.4rem] font-black text-slate-500") { @pick.player.position }
          end
        end
        unless @pick.player.position == "DST"
          img(src: nfl_team_logo_url(@pick.player.pro_team), alt: "", title: @pick.player.pro_team, loading: "lazy", class: "h-9 w-7 rounded border border-white/15 bg-slate-400/50 p-0.5 object-contain")
        end
      end
      div(class: "min-w-0") do
        p(class: "break-words text-xs font-semibold leading-tight text-slate-100") { player_name }
        p(class: "mt-0.5 text-[.6rem] font-bold leading-none text-slate-400") { position_label }
      end
    end
  end

  def mobile_empty_cell
    span(class: "w-full font-mono text-[.65rem] font-bold tabular-nums text-slate-500 min-[900px]:hidden", data: { mobile_draft_pick: @overall_number }) { pick_label }
  end

  def desktop_drafted_cell
    div(class: "hidden w-full flex-col items-center min-[900px]:flex") do
      div(class: "mb-0.5 flex shrink-0 items-center justify-center gap-1") do
        div(class: "flex size-8 items-end justify-center overflow-hidden rounded-md border border-white/15 #{portrait_background_classes} lg:size-9") do
          if @pick.player.position == "DST"
            img(src: nfl_team_logo_url(@pick.player.pro_team), alt: "", title: @pick.player.pro_team, loading: "lazy", class: "h-full w-full object-contain p-0.5")
          elsif @pick.player.headshot.attached?
            img(src: url_for(player_headshot(@pick.player, size: 64)), alt: "", loading: "lazy", class: "h-full w-full object-cover object-top")
          else
            span(class: "mb-1 text-[.45rem] font-black text-slate-500") { @pick.player.position }
          end
        end
        unless @pick.player.position == "DST"
          img(src: nfl_team_logo_url(@pick.player.pro_team), alt: "", title: @pick.player.pro_team, loading: "lazy", class: "size-7 rounded-md border border-white/15 bg-slate-400/50 p-0.5 object-contain lg:size-8")
        end
      end
      span(class: "mt-1 w-full text-balance break-words text-xs font-semibold leading-tight lg:text-sm") { player_name }
      span(class: "mt-1 text-[.6rem] font-black leading-none lg:text-xs") { position_label }
    end
  end

  def portrait_background_classes
    @pick.player.position == "DST" ? "bg-slate-400/50" : "bg-slate-800"
  end

  def mobile_portrait_size_classes
    @pick.player.position == "DST" ? "size-8" : "h-10 w-8"
  end

  def position_label
    return @pick.player.position unless @draft.complete?

    adp = @pick.player.adp ? Kernel.format("%.1f", @pick.player.adp) : "—"
    "#{@pick.player.position} - ADP #{adp}"
  end

  def player_name
    return @pick.player.name unless @pick.player.position == "DST"

    @pick.player.name.sub(/\s+Defense\z/i, "")
  end

  def pick_label
    teams_per_round = @draft.draft_entries.size
    round = ((@overall_number - 1) / teams_per_round) + 1
    pick_in_round = ((@overall_number - 1) % teams_per_round) + 1
    "#{round}.#{pick_in_round}"
  end
end
