# frozen_string_literal: true

class Components::Admin::Leagues::Index < Components::Base
  def initialize(leagues:)
    @leagues = leagues
  end

  def view_template
    div(class: "mb-6 flex items-end justify-between") do
      h1(class: "text-2xl font-semibold") { "Leagues" }
      a(href: new_admin_league_path, class: "rounded-lg bg-lime-400 px-4 py-2 font-semibold text-slate-950") { "+ New league" }
    end
    div(class: "space-y-3") do
      @leagues.each do |league|
        a(href: admin_league_path(league), class: "block rounded-xl border border-white/10 bg-slate-900 p-4 font-bold hover:border-lime-400") { "#{league.name} · #{league.season}" }
      end
    end
  end
end
