# frozen_string_literal: true

class Components::Drafts::Results < Components::Base
  def initialize(draft:, picks:, pick_elapsed_seconds:, current_user: nil, selected_team: nil)
    @draft = draft
    @picks = picks
    @pick_elapsed_seconds = pick_elapsed_seconds
    @current_user = current_user
    @selected_team = selected_team
  end

  def view_template
    section(class: "mb-4 flex flex-col gap-4 rounded-lg border border-blue-400/25 bg-blue-400/10 p-5 sm:flex-row sm:items-center sm:justify-between") do
      div do
        p(class: "text-xs font-bold uppercase tracking-[.2em] text-blue-300") { "Draft complete" }
        h2(class: "mt-1 text-xl font-bold") { "Draft results" }
        p(class: "mt-1 text-sm text-slate-400") { "#{@picks.size} selections across #{@draft.rounds} rounds." }
      end
      div(class: "flex flex-wrap gap-2") do
        a(href: draft_path(@draft.public_id), class: "rounded-lg border border-white/15 px-4 py-2 text-sm font-bold text-white hover:border-white/40") { "Draft board" }
        a(href: draft_path(@draft.public_id, view: "my_team", team_id: roster_team_id), class: "rounded-lg bg-blue-300 px-4 py-2 text-sm font-bold text-slate-950 hover:bg-blue-200") { @current_user&.commissioner? ? "Review a team" : "My team" }
        if @draft.league.espn_seasons.exists?
          a(href: league_history_path(@draft.league), class: "rounded-lg bg-lime-400 px-4 py-2 text-sm font-bold text-slate-950 hover:bg-lime-300") { "League history" }
        end
        a(href: draft_export_path(@draft.public_id, format: :csv), class: "rounded-lg bg-white px-4 py-2 text-sm font-bold text-slate-950 hover:bg-slate-200") { "Export CSV" }
      end
    end
  end

  def roster_team_id
    return unless @current_user&.commissioner?

    @selected_team&.id || @draft.draft_entries.first&.team_id
  end
end
