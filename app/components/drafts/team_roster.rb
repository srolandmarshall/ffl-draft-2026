# frozen_string_literal: true

class Components::Drafts::TeamRoster < Components::Base
  POSITION_ORDER = %w[QB RB WR TE K DST].freeze

  def initialize(draft:, team:, picks:, pick_elapsed_seconds:, commissioner: false)
    @draft = draft
    @team = team
    @picks = picks.select { |pick| pick.team_id == team&.id }
    @pick_elapsed_seconds = pick_elapsed_seconds
    @commissioner = commissioner
  end

  def view_template
    section(class: "overflow-hidden rounded-xl border border-white/10 bg-slate-900", data: { roster_team_id: @team&.id }) do
      roster_header
      team_selector if @commissioner
      @picks.any? ? roster_groups : empty_state
    end
  end

  private

  def roster_header
    header(class: "border-b border-white/10 bg-blue-300/10 px-4 py-4 sm:px-5") do
      p(class: "text-[.65rem] font-bold uppercase tracking-[.2em] text-blue-300") { @commissioner ? "Roster review" : "My team" }
      h2(class: "mt-1 break-words text-xl font-black text-white sm:text-2xl") { @team&.name || "No team available" }
      p(class: "mt-1 text-xs text-slate-400") do
        plain "#{@picks.size} #{@picks.size == 1 ? 'player' : 'players'} drafted"
        plain " · #{@team.owner_name}" if @team&.owner_name.present?
      end
    end
  end

  def team_selector
    nav(class: "flex gap-2 overflow-x-auto border-b border-white/10 px-3 py-2", aria: { label: "Choose roster team" }) do
      @draft.draft_entries.each do |entry|
        selected = entry.team_id == @team&.id
        a(
          href: draft_path(@draft.public_id, view: "my_team", team_id: entry.team_id),
          class: "shrink-0 rounded-full border px-3 py-1.5 text-xs font-bold transition #{selected ? 'border-blue-300 bg-blue-300 text-slate-950' : 'border-white/15 text-slate-300 hover:border-white/40 hover:text-white'}",
          aria: { current: ("page" if selected) }
        ) { entry.team.abbreviation }
      end
    end
  end

  def roster_groups
    div(class: "divide-y divide-white/10") do
      grouped_picks.each do |position, picks|
        section(class: "p-3 sm:p-4") do
          div(class: "mb-2 flex items-center justify-between gap-3") do
            h3(class: "text-xs font-black uppercase tracking-wider text-slate-300") { position }
            span(class: "text-[.65rem] font-bold text-slate-500") { "#{picks.size} drafted" }
          end
          div(class: "grid gap-2 sm:grid-cols-2 xl:grid-cols-3") do
            picks.each { |pick| roster_pick(pick) }
          end
        end
      end
    end
  end

  def grouped_picks
    @picks.group_by { |pick| pick.player.position }.sort_by do |position, _picks|
      [ POSITION_ORDER.index(position) || POSITION_ORDER.size, position ]
    end
  end

  def roster_pick(pick)
    article(class: "flex min-w-0 items-center gap-3 rounded-lg border border-white/10 bg-slate-950/40 p-2.5", data: { roster_pick_id: pick.id }) do
      player_image(pick.player)
      div(class: "min-w-0 flex-1") do
        p(class: "break-words text-sm font-bold leading-tight text-white") { player_name(pick.player) }
        div(class: "mt-1 flex flex-wrap items-center gap-x-2 gap-y-1 text-[.65rem] font-semibold text-slate-400") do
          span { pick.player.position }
          span { pick.player.pro_team }
          span { "R#{pick.round} · Pick #{pick.overall_number}" }
        end
      end
      span(class: "shrink-0 font-mono text-xs font-bold tabular-nums #{pick_duration_classes(elapsed_seconds(pick))}", title: "Time used for this pick") { format_pick_duration(elapsed_seconds(pick)) }
    end
  end

  def player_image(player)
    div(class: "flex h-12 w-10 shrink-0 items-end justify-center overflow-hidden rounded-md border border-white/10 #{player.position == 'DST' ? 'bg-slate-400/50' : 'bg-slate-800'}") do
      if player.position == "DST"
        img(src: nfl_team_logo_url(player.pro_team), alt: "", title: player.pro_team, loading: "lazy", class: "h-full w-full object-contain p-1")
      elsif player.headshot.attached?
        img(src: url_for(player_headshot(player, size: 80)), alt: "", loading: "lazy", class: "h-full w-full object-cover object-top")
      else
        span(class: "mb-2 text-[.55rem] font-black text-slate-500") { player.position }
      end
    end
  end

  def player_name(player)
    return player.name unless player.position == "DST"

    player.name.sub(/\s+Defense\z/i, "")
  end

  def elapsed_seconds(pick)
    @pick_elapsed_seconds.fetch(pick.id) { @pick_elapsed_seconds.fetch(pick.id.to_s, pick.elapsed_seconds.to_i) }
  end

  def empty_state
    div(class: "px-4 py-12 text-center") do
      p(class: "font-bold text-slate-200") { "No picks yet" }
      p(class: "mt-1 text-sm text-slate-500") { "This roster will update here as players are drafted." }
    end
  end
end
