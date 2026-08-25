# frozen_string_literal: true

class Components::Admin::Players::Index < Components::Base
  def initialize(players:, player_count:)
    @players = players
    @player_count = player_count
  end

  def view_template
    header
    div(class: "overflow-hidden rounded-lg border border-white/10 bg-slate-900") do
      table(class: "w-full text-left text-sm") do
        table_header
        tbody(class: "divide-y divide-white/5") { @players.each { |player| player_row(player) } }
      end
    end
  end

  private

  def header
    div(class: "mb-7 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between") do
      div do
        p(class: "text-sm font-bold text-lime-400") { "Player pool" }
        h1(class: "text-2xl font-semibold") { "Players" }
        p(class: "mt-1 text-sm text-slate-400") { "#{@player_count} total; ordered by current ADP." }
      end
      div(class: "flex flex-wrap gap-3") do
        link("Refresh ADP", new_admin_adp_import_path)
        button_to("Sync ESPN player pool", admin_espn_player_sync_path, class: action_classes)
        button_to("Refresh actual stats", admin_nflverse_player_sync_path, class: action_classes)
        link("Import CSV", new_admin_player_import_path)
        a(href: new_admin_player_path, class: "rounded bg-lime-400 px-4 py-2 font-semibold text-slate-950") { "+ Add player" }
      end
    end
  end

  def link(label, href)
    a(href:, class: action_classes) { label }
  end

  def action_classes = "cursor-pointer rounded border border-white/15 px-4 py-2 font-semibold hover:border-lime-400"

  def table_header
    thead(class: "bg-slate-800 text-xs uppercase tracking-wider text-slate-400") do
      tr do
        [ "Player", "Pos", "NFL", "ADP" ].each { |heading| th(class: "px-3 py-3 first:px-4") { heading } }
        th(class: "hidden px-3 py-3 sm:table-cell") { "ESPN ID" }
        th
      end
    end
  end

  def player_row(player)
    tr do
      td(class: "px-4 py-3 font-bold") do
        plain player.name
        span(class: "ml-2 text-xs text-slate-500") { "inactive" } unless player.active?
      end
      td(class: "px-3 py-3") { player.position }
      td(class: "px-3 py-3 text-slate-400") { player.pro_team }
      td(class: "px-3 py-3 text-slate-300") { player.adp_formatted || "—" }
      td(class: "hidden px-3 py-3 text-slate-500 sm:table-cell") { player.espn_id || "—" }
      td(class: "px-4 py-3 text-right") { a(href: edit_admin_player_path(player), class: "font-bold text-lime-400") { "Edit" } }
    end
  end
end
