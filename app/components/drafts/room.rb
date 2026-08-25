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
        controller: "draft-pick",
        action: "draft:turn->draft-pick#turnChanged",
        draft_pick_selected_team_id_value: @room.selected_team&.id,
        draft_pick_commissioner_value: @current_user.commissioner?.to_s
      }
    ) do
      clock
      navigation
      div { render recent_picks }
      section(class: "min-w-0") { render @view == "board" ? board : players }
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
    nav(class: "grid grid-cols-2 overflow-hidden rounded-xl border border-white/15 bg-slate-900 shadow-xl shadow-black/20", aria: { label: "Draft room view" }) do
      navigation_link("Player list", "Search, compare, and make your pick", draft_path(@draft.public_id), active: @view != "board")
      navigation_link("Draft board", "See every team and round at once", draft_path(@draft.public_id, view: "board"), active: @view == "board", board: true)
    end
  end

  def navigation_link(label, description, href, active:, board: false)
    classes = if active
      board ? "bg-lime-400 text-slate-950" : "bg-white text-slate-950"
    else
      board ? "text-lime-400 hover:bg-white/5" : "text-slate-400 hover:bg-white/5 hover:text-white"
    end

    a(href:, class: "group px-4 py-4 transition sm:px-5 #{board ? 'border-l border-white/15' : nil} #{classes}") do
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
end
