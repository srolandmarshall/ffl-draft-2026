# frozen_string_literal: true

class Components::Drafts::PlayerFilters < Components::Base
  def initialize(players:)
    @players = players
  end

  def view_template
    div(class: "border-b border-white/10 p-3 sm:p-4") do
      div(class: "flex flex-col gap-3") do
        div(class: "flex items-center gap-3") do
          input(type: "search", placeholder: "Search players…", autocomplete: "off", aria: { label: "Search players" }, class: "min-w-0 flex-1 rounded-lg border border-white/15 bg-slate-950 px-3 py-2", data: { draft_filter_target: "query", action: "input->draft-filter#search" })
          span(class: "whitespace-nowrap text-xs text-slate-500") do
            span(data: { draft_filter_target: "count" }) { @players.size }
            plain " players"
          end
        end
        div(class: "flex flex-wrap items-start justify-between gap-3") do
          position_filters
          team_filter
        end
      end
    end
  end

  private

  def position_filters
    div(class: "flex flex-wrap items-center gap-1.5 sm:gap-2", aria: { label: "Filter by position" }) do
      button(type: "button", aria: { pressed: "true" }, class: "cursor-pointer rounded-full border border-white/15 px-2.5 py-1 text-xs font-bold text-slate-300 transition hover:border-white/40 aria-pressed:border-lime-300 aria-pressed:bg-lime-400 aria-pressed:text-slate-950 sm:px-3", data: { draft_filter_target: "all", action: "draft-filter#clearPositions" }) { "All" }
      Player::POSITIONS.each do |position|
        label(class: "cursor-pointer") do
          input(type: "checkbox", value: position, class: "peer sr-only", data: { draft_filter_target: "position", action: "change->draft-filter#togglePosition" })
          span(class: "inline-flex rounded-full border border-white/15 px-2.5 py-1 text-xs font-bold text-slate-300 transition sm:px-3 #{position_filter_classes(position)}") { position }
        end
      end
    end
  end

  def team_filter
    teams = @players.map(&:pro_team).compact.uniq.sort
    return if teams.empty?

    details(class: "relative self-start") do
      summary(class: "flex cursor-pointer list-none items-center gap-2 rounded-full border border-white/15 bg-slate-950 px-3 py-1.5 text-xs font-bold text-slate-300 transition hover:border-white/40 [&::-webkit-details-marker]:hidden") do
        span { "Team" }
        span(class: "text-lime-300", data: { draft_filter_target: "teamSummary" }) { "All teams" }
        span(class: "text-slate-500") { "▾" }
      end
      div(class: "absolute right-0 top-full z-20 mt-2 grid max-h-64 min-w-56 grid-cols-2 gap-x-4 gap-y-1 overflow-y-auto rounded-xl border border-white/15 bg-slate-950 p-3 shadow-2xl shadow-black/40") do
        teams.each { |team| team_option(team) }
      end
    end
  end

  def team_option(team)
    label(class: "flex cursor-pointer items-center gap-2 rounded px-2 py-1.5 text-xs font-semibold text-slate-300 hover:bg-white/10") do
      input(type: "checkbox", value: team, class: "size-3.5 accent-lime-400", data: { draft_filter_target: "team", action: "change->draft-filter#toggleTeam" })
      img(src: nfl_team_logo_url(team), alt: team, title: team, loading: "lazy", class: "size-5 object-contain")
      span { team }
    end
  end
end
