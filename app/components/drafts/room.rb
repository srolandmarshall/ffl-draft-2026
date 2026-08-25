# frozen_string_literal: true

class Components::Drafts::Room < Components::Base
  def initialize(room:, current_user:, view: nil)
    @room = room
    @draft = room.draft
    @current_user = current_user
    @view = view
  end

  def view_template
    div(
      id: dom_id(@draft, :room),
      class: "space-y-4",
      data: {
        controller: "draft-pick draft-alert",
        action: "draft:turn->draft-pick#turnChanged draft:turn->draft-alert#turnChanged",
        draft_pick_selected_team_id_value: @room.selected_team&.id,
        draft_pick_commissioner_value: @current_user.commissioner?.to_s,
        draft_alert_selected_team_id_value: @room.selected_team&.id,
        draft_alert_current_team_id_value: @draft.current_team&.id,
        draft_alert_enabled_value: (@room.selected_team.present? && !@current_user.commissioner?).to_s,
        draft_alert_sound_url_value: "/its-your-pick.mp3"
      }
    ) do
      div(class: "grid gap-4 lg:grid-cols-[minmax(16rem,20rem)_minmax(0,1fr)] lg:items-start xl:grid-cols-[minmax(18rem,22rem)_minmax(0,1fr)]", data: { draft_room_layout: true }) do
        aside(class: "min-w-0 space-y-4 lg:sticky lg:top-4", data: { draft_room_sidebar: true }) do
          clock
          render recent_picks
        end
        main(class: "min-w-0 space-y-4", data: { draft_room_content: true }) do
          navigation
          section(class: "min-w-0") { render_active_view }
        end
      end
    end
  end

  private

  def clock
    turbo_frame_tag("draft-#{@draft.public_id}-clock", class: "sticky top-0 z-30 block") do
      render Components::Drafts::Clock.new(
        draft: @draft,
        selected_team: @room.selected_team,
        picks_until_selected_team: @room.picks_until_selected_team,
        picks: @room.picks,
        current_pick_elapsed_seconds: @room.current_pick_elapsed_seconds,
        current_user: @current_user
      )
    end
  end

  def navigation
    nav(class: "grid grid-cols-3 overflow-hidden rounded-xl border border-white/15 bg-slate-900 shadow-xl shadow-black/20", aria: { label: "Draft room view" }) do
      navigation_link("Player list", "Search, compare, and make your pick", draft_path(@draft.public_id), active: @view.blank?)
      navigation_link("Team Rosters", @current_user.commissioner? ? "Choose and review a roster" : "Review your drafted roster", roster_path, active: @view == "my_team", roster: true)
      navigation_link("Draft board", "See every team and round at once", draft_path(@draft.public_id, view: "board"), active: @view == "board", board: true)
    end
  end

  def navigation_link(label, description, href, active:, board: false, roster: false)
    classes = if active
      if board
        "bg-lime-400 text-slate-950"
      elsif roster
        "bg-blue-300 text-slate-950"
      else
        "bg-white text-slate-950"
      end
    else
      if board
        "text-lime-400 hover:bg-white/5"
      elsif roster
        "text-blue-300 hover:bg-white/5"
      else
        "text-slate-400 hover:bg-white/5 hover:text-white"
      end
    end

    a(
      href:,
      class: "group px-2 py-3 transition sm:px-5 sm:py-4 #{(board || roster) ? 'border-l border-white/15' : nil} #{classes}",
      style: ("background-color: var(--color-blue-300)" if active && roster)
    ) do
      span(class: "block text-base font-black sm:text-lg") { label }
      span(class: "mt-0.5 block text-[.65rem] font-semibold sm:text-xs") { description }
    end
  end

  def recent_picks
    Components::Drafts::RecentPicks.new(
      draft: @draft,
      picks: @room.picks,
      pick_elapsed_seconds: @room.pick_elapsed_seconds
    )
  end

  def board
    Components::Drafts::Board.new(
      draft: @draft,
      picks: @room.picks,
      pick_elapsed_seconds: @room.pick_elapsed_seconds,
      selected_team: @room.selected_team
    )
  end

  def players
    Components::Drafts::Players.new(room: @room, can_make_pick: @room.can_make_pick?(@current_user))
  end

  def team_roster
    Components::Drafts::TeamRoster.new(
      draft: @draft,
      team: @room.roster_team,
      picks: @room.picks,
      commissioner: @current_user.commissioner?,
      preferred_team: @room.selected_team
    )
  end

  def render_active_view
    if @view == "board"
      render board
    elsif @view == "my_team"
      turbo_frame_tag("draft-#{@draft.public_id}-team-roster") { render team_roster }
    else
      render players
    end
  end

  def roster_path
    draft_path(
      @draft.public_id,
      view: "my_team",
      team_id: (@room.selected_team&.id if @current_user.commissioner?)
    )
  end
end
