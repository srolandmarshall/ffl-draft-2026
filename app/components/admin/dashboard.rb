# frozen_string_literal: true

class Components::Admin::Dashboard < Components::Base
  def initialize(leagues:)
    @leagues = leagues
  end

  def view_template
    content_for(:title, "League admin")
    header
    div(class: "grid gap-4 md:grid-cols-2") do
      @leagues.each { |league| league_card(league) }
      div(class: "col-span-full rounded-lg border border-dashed border-white/15 p-10 text-center text-slate-400") { "Create your first league to begin." } if @leagues.empty?
    end
  end

  private

  def header
    div(class: "mb-8 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between") do
      div do
        h1(class: "text-2xl font-bold") { "League admin" }
        p(class: "mt-1 text-sm text-slate-400") { "Teams, players, and drafts." }
      end
      div(class: "flex gap-3") do
        action_link("Users", admin_users_path)
        action_link("Players", admin_players_path)
        a(href: new_admin_league_path, class: "rounded bg-lime-400 px-4 py-2 font-semibold text-slate-950 hover:bg-lime-300") { "+ New league" }
      end
    end
  end

  def action_link(label, href)
    a(href:, class: "rounded border border-white/15 px-4 py-2 font-semibold hover:border-white/30") { label }
  end

  def league_card(league)
    a(href: admin_league_path(league), class: "rounded-lg border border-white/10 bg-slate-900 p-5 hover:border-white/25") do
      p(class: "text-sm font-bold text-lime-400") { league.season }
      h2(class: "mt-1 text-xl font-semibold") { league.name }
      p(class: "mt-6 text-sm text-slate-400") { "#{pluralize(league.teams.active.size, 'team')} · #{pluralize(league.drafts.size, 'draft')} · #{league.roster_size} roster spots" }
    end
  end
end
