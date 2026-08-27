# frozen_string_literal: true

class Components::Drafts::UpNext < Components::Base
  def initialize(draft:)
    @draft = draft
  end

  def view_template
    return unless @draft.live?

    teams = @draft.upcoming_teams(3)
    return if teams.empty?

    section(class: "w-full overflow-hidden rounded-xl border border-white/10 bg-slate-900") do
      p(class: "border-b border-white/10 px-3 py-1.5 text-[.65rem] font-bold uppercase tracking-wider text-slate-400") { "Up next" }
      ol(class: "divide-y divide-white/5") do
        teams.each_with_index { |team, index| team_item(team, index) }
      end
    end
  end

  private

  def team_item(team, index)
    li(class: "flex items-center gap-2 px-3 py-1.5 text-xs") do
      span(class: "flex size-5 shrink-0 items-center justify-center rounded-full bg-white/10 text-[.6rem] font-bold text-slate-300") { (index + 1).to_s }
      span(class: "min-w-0 flex-1 truncate font-semibold text-slate-200") { team.name }
    end
  end
end
