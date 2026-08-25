# frozen_string_literal: true

class Components::Admin::Leagues::Delete < Components::Base
  def initialize(league:)
    @league = league
  end

  def view_template
    section(class: "mt-8 rounded-lg border border-red-400/30 bg-red-400/5 p-6") do
      h2(class: "font-semibold text-red-200") { "Delete league" }
      p(class: "mt-2 text-sm text-slate-400") { "Permanently deletes this league, including every team, draft, and pick." }
      button_to(
        "Delete league",
        admin_league_path(@league),
        method: :delete,
        class: "mt-4 cursor-pointer rounded-lg border border-red-400/40 px-4 py-2 font-bold text-red-200 hover:bg-red-400/10",
        form: { data: { turbo_confirm: "Delete #{@league.name}? This permanently deletes its teams, drafts, and picks." } }
      )
    end
  end
end
