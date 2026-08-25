# frozen_string_literal: true

class Components::Drafts::Players < Components::Base
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

  def refresh_url
    players_draft_path(@draft.public_id, @room.player_filters.compact_blank)
  end

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
        @players.each { |player| desktop_row(player) }
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

  def desktop_row(player)
    stats = PlayerStats.new(@draft, player)
    tr(class: "hover:bg-white/[.03]", data: { draft_player_id: player.id }) do
      td(class: "px-3 py-2.5") { render Components::Drafts::PlayerIdentity.new(player:, variant: :desktop) }
      td(class: "px-2 py-2.5 text-center") { span(class: "font-bold tabular-nums text-slate-300") { player.bye_week || "—" } }
      td(class: "px-2 py-2.5 text-right") { span(class: "text-base font-black tabular-nums text-lime-400") { points(stats) } }
      td(class: "px-2 py-2.5 text-center") { span(class: "font-bold tabular-nums text-slate-200") { player.draft_games || "—" } }
      td(class: "px-2 py-2.5 text-center") { render Components::Drafts::Touchdowns.new(stats: stats.touchdowns) }
      td(class: "px-3 py-2.5") { render Components::Drafts::ProductionGroups.new(groups: stats.groups) }
      td(class: "px-3 py-2.5 text-right") { render Components::Drafts::Action.new(draft: @draft, player:, can_make_pick: @can_make_pick) }
    end
  end

  def mobile_list
    div(class: "divide-y divide-white/5 md:hidden") do
      @players.each { |player| mobile_row(player) }
      div(class: "px-5 py-10 text-center text-sm text-slate-500") { "No players match those filters." } if @players.empty?
    end
  end

  def mobile_row(player)
    stats = PlayerStats.new(@draft, player)
    article(class: "p-3", data: { draft_player_id: player.id }) do
      div(class: "flex items-start justify-between gap-3") do
        render Components::Drafts::PlayerIdentity.new(player:, variant: :mobile)
        render Components::Drafts::Action.new(draft: @draft, player:, can_make_pick: @can_make_pick)
      end
      mobile_summary(player, stats)
      render Components::Drafts::Touchdowns.new(stats: stats.touchdowns, variant: :mobile)
      render Components::Drafts::ProductionGroups.new(groups: stats.groups, variant: :mobile)
    end
  end

  def mobile_summary(player, stats)
    dl(class: "mt-2 grid grid-cols-3 border-y border-white/10 py-2") do
      metric("Bye", player.bye_week || "—")
      metric("#{prior_season} FP", points(stats), separated: true, accent: true)
      metric("Games", player.draft_games || "—", separated: true)
    end
  end

  def metric(label, value, separated: false, accent: false)
    div(class: separated ? "border-l border-white/10 pl-4" : nil) do
      dt(class: "text-[.6rem] font-bold uppercase tracking-wider #{accent ? 'text-lime-300' : 'text-slate-500'}") { label }
      dd(class: "text-xl font-black tabular-nums #{accent ? 'text-lime-300' : 'text-slate-100'}") { value }
    end
  end

  def empty_table_row
    tr { td(colspan: 7, class: "px-5 py-10 text-center text-sm text-slate-500") { "No players match those filters." } }
  end

  def source_note
    p(class: "border-t border-white/10 px-4 py-2 text-[.65rem] text-slate-500") do
      plain "#{prior_season} regular-season results from "
      a(href: "https://github.com/nflverse/nflverse-data/releases/tag/stats_player", target: "_blank", rel: "noopener", class: "underline hover:text-slate-300") { "nflverse" }
      plain ". Fantasy points use #{@draft.league.name}'s ESPN scoring rules."
    end
  end

  def prior_season = @draft.league.season - 1

  def points(stats)
    stats.fantasy_points ? number_with_precision(stats.fantasy_points, precision: 1) : "—"
  end

  class PlayerStats
    attr_reader :fantasy_points, :groups, :touchdowns

    def initialize(draft, player)
      league_score = draft.prior_season_score_for(player)
      @fantasy_points = league_score&.points
      @groups = player.position == "DST" ? (league_score&.dst_stat_groups || []) : player.draft_stat_groups
      @touchdowns = player.position == "DST" ? (league_score&.dst_touchdown_stats || []) : player.draft_touchdown_stats
    end
  end
end
