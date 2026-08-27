# frozen_string_literal: true

class Components::Drafts::PlayerFilters < Components::Base
  def initialize(draft:, players:, available_teams:, filters:)
    @draft = draft
    @players = players
    @available_teams = available_teams
    @query = filters.fetch(:query, "")
    @positions = filters.fetch(:positions, [])
    @teams = filters.fetch(:teams, [])
  end

  def view_template
    form(action: players_draft_path(@draft.public_id), method: "get", class: "border-b border-white/10 p-3 sm:p-4", data: { controller: "draft-filter", turbo_frame: frame_id }) do
      div(class: "flex flex-col gap-3") do
        div(class: "flex items-center gap-3") do
          input(id: "#{frame_id}-query", type: "search", name: "query", value: @query, placeholder: "Search players…", autocomplete: "off", aria: { label: "Search players" }, class: "min-w-0 flex-1 rounded-lg border border-white/15 bg-slate-950 px-3 py-2", data: { turbo_permanent: true, draft_filter_target: "query", action: "input->draft-filter#scheduleSubmit" })
          span(class: "whitespace-nowrap text-xs text-slate-500", aria: { live: "polite" }) do
            span { @players.size }
            plain " players"
          end
        end
        div(class: "flex flex-col items-stretch gap-3 sm:flex-row sm:flex-wrap sm:items-start sm:justify-between") do
          position_filters
          team_filter
        end
        div(class: "flex items-center justify-end") do
          button(type: "button", class: "cursor-pointer rounded px-3 py-1.5 text-xs font-bold text-slate-400 transition hover:bg-white/10 hover:text-white", data: { action: "draft-filter#clearFilters" }) { "Clear filters" }
        end
      end
    end
  end

  private

  def frame_id = "draft-#{@draft.public_id}-players"

  def position_filters
    div(class: "flex flex-wrap items-center gap-1.5 sm:gap-2", aria: { label: "Filter by position" }) do
      button(type: "button", aria: { pressed: @positions.empty?.to_s }, class: "cursor-pointer rounded-full border border-white/15 px-2.5 py-1 text-xs font-bold text-slate-300 transition hover:border-white/40 aria-pressed:border-lime-300 aria-pressed:bg-lime-400 aria-pressed:text-slate-950 sm:px-3", data: { draft_filter_target: "all", action: "draft-filter#clearPositions" }) { "All" }
      Player::POSITIONS.each do |position|
        label(class: "cursor-pointer") do
          input(type: "checkbox", name: "positions[]", value: position, checked: @positions.include?(position), class: "peer sr-only", data: { draft_filter_target: "position", action: "change->draft-filter#scheduleSubmit" })
          span(class: "inline-flex rounded-full border border-white/15 px-2.5 py-1 text-xs font-bold text-slate-300 transition sm:px-3 #{position_filter_classes(position)}") { position }
        end
      end
    end
  end

  def team_filter
    return if @available_teams.empty?

    details(class: "relative w-full self-start sm:w-auto") do
      summary(class: "flex cursor-pointer list-none items-center justify-between gap-2 rounded-full border border-white/15 bg-slate-950 px-3 py-1.5 text-xs font-bold text-slate-300 transition hover:border-white/40 sm:justify-start [&::-webkit-details-marker]:hidden") do
        span { "Team" }
        span(class: "text-lime-300", data: { draft_filter_target: "teamCount" }) { @teams.empty? ? "All teams" : "#{@teams.size} selected" }
        span(class: "text-slate-500") { "▾" }
      end
      div(class: "absolute inset-x-0 top-full z-20 mt-2 grid max-h-64 w-full grid-cols-2 gap-x-4 gap-y-1 overflow-y-auto rounded-xl border border-white/15 bg-slate-950 p-3 shadow-2xl shadow-black/40 sm:left-auto sm:right-0 sm:w-auto sm:min-w-56") do
        @available_teams.each { |team| team_option(team) }
        div(class: "col-span-2 sticky bottom-0 -mx-3 -mb-3 mt-2 flex items-center justify-between gap-2 border-t border-white/10 bg-slate-950 px-3 py-2") do
          button(type: "button", class: "cursor-pointer rounded px-2 py-1 text-xs font-bold text-slate-400 transition hover:bg-white/10 hover:text-white", data: { action: "draft-filter#clearTeams" }) { "Clear" }
        end
      end
    end
  end

  def team_option(team)
    label(class: "flex cursor-pointer items-center gap-2 rounded px-2 py-1.5 text-xs font-semibold text-slate-300 hover:bg-white/10") do
      input(type: "checkbox", name: "teams[]", value: team, checked: @teams.include?(team), class: "size-3.5 accent-lime-400", data: { draft_filter_target: "team", action: "change->draft-filter#updateTeamSelection change->draft-filter#scheduleSubmit" })
      img(src: nfl_team_logo_url(team), alt: team, title: team, loading: "lazy", class: "size-7 rounded bg-slate-400/50 p-0.5 object-contain")
      span { team }
    end
  end
end
