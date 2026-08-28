# frozen_string_literal: true

# The draftable player list: filters, both breakpoint layouts, and the source note.
#
# Desktop and mobile are deliberately separate markup rather than one responsive layout - a
# table and a card list do not reflow into each other - so this renders every player twice and
# leans on `PlayerDraftStats` to keep the two in step.
class Components::Drafts::Players < Components::Base
  EMPTY_MESSAGE = "No players match those filters."

  def initialize(room:, can_make_pick:)
    @room = room
    @draft = room.draft
    @players = room.available_players
    @can_make_pick = can_make_pick
  end

  def view_template
    turbo_frame_tag(frame_id, data: { player_refresh_url: refresh_url }) do
      div(class: "rounded-lg border border-white/10 bg-slate-900") do
        render filters
        div do
          desktop_table
          mobile_list
        end
        source_note
      end
    end
  end

  private

  def frame_id = "draft-#{@draft.public_id}-players"
  def prior_season = @draft.league.season - 1

  def refresh_url
    players_draft_path(@draft.public_id, @room.player_filters.compact_blank)
  end

  # Resolved once per player and shared by both breakpoints.
  def stats_for(player) = PlayerDraftStats.new(@draft, player)

  def filters
    Components::Drafts::PlayerFilters.new(
      draft: @draft,
      players: @players,
      available_teams: @room.available_teams,
      filters: @room.player_filters
    )
  end

  def desktop_table
    table(class: "hidden w-full table-fixed text-left text-xs md:table") do
      colgroup do
        %w[w-[23%] w-[5%] w-[9%] w-[6%] w-[8%] w-[39%] w-[10%]].each { |width| col(class: width) }
      end
      thead(class: "sticky top-0 z-10 bg-slate-800 uppercase tracking-wider text-slate-400") { table_header }
      tbody(class: "divide-y divide-white/5") do
        @players.each { |player| render row_for(player) }
        empty_table_row if @players.empty?
      end
    end
  end

  def table_header
    tr do
      th(class: "px-3 py-3") { "Player" }
      th(class: "px-2 py-3 text-center") { "Bye" }
      th(class: "px-2 py-3 text-right") { "#{prior_season} FP" }
      th(class: "px-2 py-3 text-center") { "Games" }
      th(class: "px-2 py-3 text-center") { "TDs" }
      th(class: "px-3 py-3") { "#{prior_season} production" }
      th(class: "px-3 py-3 text-right") { "Action" }
    end
  end

  def row_for(player)
    Components::Drafts::PlayerRow.new(
      draft: @draft,
      player:,
      stats: stats_for(player),
      can_make_pick: @can_make_pick
    )
  end

  def mobile_list
    div(class: "divide-y divide-white/15 md:hidden") do
      @players.each { |player| render card_for(player) }
      div(class: "px-5 py-10 text-center text-sm text-slate-500") { EMPTY_MESSAGE } if @players.empty?
    end
  end

  def card_for(player)
    Components::Drafts::PlayerCard.new(
      draft: @draft,
      player:,
      stats: stats_for(player),
      can_make_pick: @can_make_pick,
      prior_season:
    )
  end

  def empty_table_row
    tr { td(colspan: 7, class: "px-5 py-10 text-center text-sm text-slate-500") { EMPTY_MESSAGE } }
  end

  def source_note
    p(class: "border-t border-white/10 px-4 py-2 text-[.65rem] text-slate-500") do
      plain "#{prior_season} regular-season results from "
      a(href: "https://github.com/nflverse/nflverse-data/releases/tag/stats_player", target: "_blank", rel: "noopener", class: "underline hover:text-slate-300") { "nflverse" }
      plain ". Fantasy points use #{@draft.league.name}'s ESPN scoring rules."
      sources = @players.map(&:ranking_source).compact.uniq
      if sources.any?
        plain " "
        render Components::RankingAttribution.new(sources:)
        plain "."
      end
    end
  end
end
