# frozen_string_literal: true

class Components::Drafts::RecentPicks < Components::Base
  def initialize(draft:, picks:, pick_elapsed_seconds:, pick_count: picks.size)
    @draft = draft
    @picks = picks
    @pick_elapsed_seconds = pick_elapsed_seconds
    @pick_count = pick_count
  end

  def view_template
    section(id: "draft-#{@draft.public_id}-recent-picks", class: "w-full overflow-hidden rounded-xl border border-white/10 bg-slate-900") do
      div(class: "border-b border-white/10") do
        p(class: "border-b border-white/10 px-3 py-1.5 text-[.65rem] font-bold uppercase tracking-wider text-slate-400") { "Recent picks · #{@pick_count}/#{@draft.total_picks}" }
        ol(class: "grid max-h-32 grid-cols-2 overflow-y-auto sm:grid-cols-4 lg:max-h-[calc(100vh-18rem)] lg:grid-cols-1") do
          @picks.last(12).reverse_each.with_index do |pick, index|
            pick_item(pick, desktop_only: index >= 4)
          end
          li(class: "col-span-full px-4 py-4 text-center text-xs text-slate-500") { "No picks yet." } if @picks.empty?
        end
      end
    end
  end

  private

  def pick_item(pick, desktop_only:)
    elapsed = @pick_elapsed_seconds.fetch(pick.id) { @pick_elapsed_seconds.fetch(pick.id.to_s, 0) }
    visibility_classes = desktop_only ? "hidden lg:flex" : "flex"
    li(class: "#{visibility_classes} min-w-0 items-center gap-2 border-b border-r border-white/5 px-2 py-1.5 text-[.65rem] sm:text-xs", data: { recent_pick: "" }) do
      render Components::PlayerPortrait.new(
        player: pick.player,
        frame: "size-8 shrink-0 rounded-full border border-white/10"
      )
      div(class: "min-w-0 flex-1") do
        div(class: "flex items-center gap-1.5") do
          span(class: "min-w-0 flex-1 truncate font-bold") { pick.player.name }
          span(class: "shrink-0 rounded border px-1 py-0.5 text-[.5rem] #{position_badge_classes(pick.player.position)}") { pick.player.position }
        end
        div(class: "mt-0.5 flex items-center justify-between gap-2") do
          span(class: "min-w-0 truncate font-semibold text-slate-500", title: pick.team.name) { "#{pick.team.abbreviation} · R#{pick.round} · Pick #{pick.overall_number}" }
          span(class: "shrink-0 font-mono font-bold tabular-nums #{pick_duration_classes(elapsed)}", title: "Time used for this pick") { format_pick_duration(elapsed) }
        end
      end
    end
  end
end
