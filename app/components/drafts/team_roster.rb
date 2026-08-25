# frozen_string_literal: true

class Components::Drafts::TeamRoster < Components::Base
  def initialize(draft:, team:, picks:, commissioner: false, preferred_team: team)
    @draft = draft
    @team = team
    @picks = picks.select { |pick| pick.team_id == team&.id }
    @slots = ::Drafts::RosterSlots.new(draft:, picks: @picks).call
    @commissioner = commissioner
    @preferred_team = preferred_team
  end

  def view_template
    section(class: "overflow-hidden rounded-xl border border-white/10 bg-slate-900", data: { roster_team_id: @team&.id }) do
      roster_header
      team_selector if @commissioner
      roster_skeleton
    end
  end

  private

  def roster_header
    header(class: "border-b border-white/10 bg-blue-300/10 px-4 py-4 sm:px-5") do
      p(class: "text-[.65rem] font-bold uppercase tracking-[.2em] text-blue-300") { "Team Rosters" }
      h2(class: "mt-1 break-words text-xl font-black text-white sm:text-2xl") { @team&.name || "No team available" }
      p(class: "mt-1 text-xs text-slate-400") do
        plain "#{@picks.size} of #{@draft.roster_size} roster slots filled"
        plain " · #{@team.owner_name}" if @team&.owner_name.present?
      end
    end
  end

  def team_selector
    nav(class: "flex gap-2 overflow-x-auto border-b border-white/10 px-3 py-2", aria: { label: "Choose roster team" }) do
      roster_entries.each do |entry|
        selected = entry.team_id == @team&.id
        a(
          href: draft_path(@draft.public_id, view: "my_team", team_id: entry.team_id),
          class: "shrink-0 rounded-full border px-3 py-1.5 text-xs font-bold transition #{selected ? 'text-slate-950' : 'border-white/15 text-slate-300 hover:border-white/40 hover:text-white'}",
          style: ("background-color: var(--color-blue-300); border-color: var(--color-blue-300)" if selected),
          aria: { current: ("page" if selected) }
        ) { entry.team.abbreviation }
      end
    end
  end

  def roster_skeleton
    div(class: "divide-y divide-white/10") do
      slot_group("Starting lineup", starter_slots)
      slot_group("Bench", bench_slots)
    end
  end

  def slot_group(title, slots)
    return if slots.empty?

    section(class: "p-3 sm:p-4") do
      div(class: "mb-2 flex items-center justify-between gap-3") do
        h3(class: "text-xs font-black uppercase tracking-wider text-slate-300") { title }
        span(class: "text-[.65rem] font-bold text-slate-500") { "#{slots.count(&:filled?)} of #{slots.size} filled" }
      end
      div(class: "grid gap-2 sm:grid-cols-2 xl:grid-cols-3") do
        slots.each { |slot| roster_slot(slot) }
      end
    end
  end

  def starter_slots = @slots.reject(&:bench)
  def bench_slots = @slots.select(&:bench)

  def roster_slot(slot)
    article(
      class: "flex min-w-0 items-center gap-2.5 rounded-lg border px-2.5 py-1.5 #{slot.filled? ? 'border-white/10 bg-slate-950/40' : 'border-dashed border-white/10 bg-slate-950/20'}",
      style: "height: 3.5rem",
      data: { roster_slot: slot.label, roster_slot_position: slot.position, roster_filled: slot.filled?.to_s, roster_pick_id: slot.pick&.id }
    ) do
      span(class: "flex w-11 shrink-0 items-center justify-center self-stretch rounded-md border border-white/10 bg-white/5 px-1 text-center text-[.65rem] font-black text-blue-300") { slot.label }
      if slot.filled?
        player_image(slot.pick.player)
        div(class: "min-w-0 flex-1") do
          p(class: "break-words text-sm font-bold leading-tight text-white") { player_name(slot.pick.player) }
          div(class: "mt-1 flex flex-wrap items-center gap-x-2 gap-y-1 text-[.65rem] font-semibold text-slate-400") do
            span { slot.pick.player.position }
            span { slot.pick.player.pro_team }
            span { "R#{slot.pick.round} · Pick #{slot.pick.overall_number}" }
          end
        end
      else
        div(class: "min-w-0 flex-1") do
          p(class: "text-sm font-semibold text-slate-500") { "Available" }
          p(class: "mt-0.5 text-[.65rem] text-slate-600") { slot_hint(slot) }
        end
      end
    end
  end

  def slot_hint(slot)
    return "Any position" if slot.bench
    return "RB, WR, or TE" if slot.position == "FLEX"

    slot.label
  end

  def player_image(player)
    if player.position == "DST"
      img(src: nfl_team_logo_url(player.pro_team), alt: "", title: player.pro_team, loading: "lazy", class: "shrink-0 object-contain p-0.5", style: player_image_style, data: { roster_player_image: true })
    elsif player.headshot.attached?
      img(src: url_for(player_headshot(player, size: 80)), alt: "", loading: "lazy", class: "shrink-0 rounded-md object-cover object-top", style: player_image_style, data: { roster_player_image: true })
    else
      span(class: "flex shrink-0 items-center justify-center text-[.55rem] font-black text-slate-500", style: player_image_style) { player.position }
    end
  end

  def player_image_style = "height: 2.75rem; width: 2.25rem"

  def player_name(player)
    return player.name unless player.position == "DST"

    player.name.sub(/\s+Defense\z/i, "")
  end

  def roster_entries
    @draft.draft_entries.sort_by { |entry| entry.team_id == @preferred_team&.id ? 0 : 1 }
  end
end
