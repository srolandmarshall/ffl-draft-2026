# frozen_string_literal: true

class Components::LeagueStories::DraftArchaeology < Components::Base
  def initialize(draft_value:)
    @steals = draft_value.steals(limit: 8)
    @busts = draft_value.busts(limit: 8)
  end

  def view_template
    return if @steals.empty? && @busts.empty?

    section(class: "mb-10") do
      div(class: "mb-5") do
        p(class: "text-xs font-bold uppercase tracking-[.2em] text-blue-300") { "Draft archaeology" }
        h2(class: "mt-1 text-2xl font-black sm:text-3xl") { "What the board got wrong" }
        p(class: "mt-2 max-w-3xl text-sm text-slate-400") do
          "Each pick measured against the positional slot it cost. The fourth back off the board is expected to finish RB4; everything else is a swing."
        end
      end
      div(class: "grid gap-5 lg:grid-cols-2") do
        table("Steals", @steals, "text-lime-300")
        table("Busts", @busts, "text-rose-300")
      end
    end
  end

  private

  def table(title, picks, accent)
    return if picks.blank?

    div(class: "overflow-hidden rounded-2xl border border-white/10 bg-slate-900") do
      p(class: "border-b border-white/5 px-4 py-3 text-xs font-bold uppercase tracking-[.16em] text-slate-400") { title }
      ol(class: "divide-y divide-white/5") { picks.each { |pick| row(pick, accent) } }
    end
  end

  def row(pick, accent)
    li(class: "flex items-center gap-3 px-4 py-2.5") do
      div(class: "min-w-0 flex-1") do
        p(class: "truncate text-sm font-black") { pick.player_name }
        p(class: "truncate text-xs text-slate-500") do
          "#{pick.season} · pick #{pick.overall_pick} · #{pick.franchise&.name || pick.team_name}"
        end
      end
      div(class: "shrink-0 text-right") do
        p(class: "text-sm font-black tabular-nums #{accent}") do
          "#{pick.position}#{pick.position_draft_rank} → #{pick.position}#{pick.position_rank}"
        end
        p(class: "text-[10px] font-bold uppercase tracking-wider text-slate-600") do
          "#{number_with_precision(pick.points, precision: 1)} pts"
        end
      end
    end
  end
end
