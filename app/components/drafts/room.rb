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
      room_layout
    end
  end

  private

  def room_layout
    div(class: "grid gap-4 lg:grid-cols-[minmax(16rem,20rem)_minmax(0,1fr)] lg:items-start xl:grid-cols-[minmax(18rem,22rem)_minmax(0,1fr)]", data: { draft_room_layout: true }) do
      sidebar_column
      main_column
      room_content if board_view?
    end
  end

  # Bundles clock + recent picks into a single grid cell so this column's height
  # never stretches the other column's row track and pushes its contents apart.
  def sidebar_column
    div(class: "min-w-0 space-y-4 lg:col-start-1 lg:row-start-1") do
      clock
      recent_picks_panel unless board_view?
    end
  end

  # Bundles nav + up next + content (unless it needs the full board-view width)
  # for the same reason as sidebar_column.
  def main_column
    div(class: "min-w-0 space-y-4 lg:col-start-2 lg:row-start-1") do
      navigation
      up_next
      room_content unless board_view?
    end
  end

  def recent_picks_panel
    aside(class: "min-w-0", data: { draft_room_sidebar: true }) { render recent_picks }
  end

  def room_content
    classes = board_view? ? "min-w-0 lg:col-span-2 lg:col-start-1 lg:row-start-2" : "min-w-0"
    main(class: classes, data: { draft_room_content: true }) do
      section(class: "min-w-0") { render_active_view }
    end
  end

  def clock
    turbo_frame_tag("draft-#{@draft.public_id}-clock", class: "sticky top-0 z-30 block min-w-0") do
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

  def up_next
    turbo_frame_tag("draft-#{@draft.public_id}-up-next", class: "block min-w-0") do
      render Components::Drafts::UpNext.new(draft: @draft)
    end
  end

  def navigation
    nav(class: "grid min-w-0 grid-cols-3 overflow-hidden rounded-xl border border-white/15 bg-slate-900 shadow-xl shadow-black/20", aria: { label: "Draft room view" }) do
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

  def board_view? = @view == "board"

  def roster_path
    draft_path(
      @draft.public_id,
      view: "my_team",
      team_id: (@room.selected_team&.id if @current_user.commissioner?)
    )
  end
end
