# frozen_string_literal: true

# One player as a card in the mobile draft list.
#
# Renders the same player and the same stats as the desktop row; the season breakdown is
# collapsed behind a disclosure because it does not fit beside the pick action at this width.
class Components::Drafts::PlayerCard < Components::Base
  def initialize(draft:, player:, stats:, can_make_pick:, prior_season:)
    @draft = draft
    @player = player
    @stats = stats
    @can_make_pick = can_make_pick
    @prior_season = prior_season
  end

  def view_template
    article(
      class: "px-3 py-2 #{position_surface_classes(@player.position)}",
      data: { draft_player_id: @player.id, mobile_player_row: true }
    ) do
      div(class: "flex items-start justify-between gap-2") do
        render Components::Drafts::PlayerIdentity.new(player: @player, variant: :mobile)
        render Components::Drafts::Action.new(draft: @draft, player: @player, can_make_pick: @can_make_pick)
      end
      summary_metrics
      season_stats_details
    end
  end

  private

  def summary_metrics
    dl(class: "mt-1.5 grid grid-cols-4 border-y border-white/10 py-1.5") do
      metric("Bye", @stats.bye_week)
      metric("#{@prior_season} FP", @stats.points, separated: true, accent: true)
      metric("Games", @stats.games, separated: true)
      metric("TDs", @stats.touchdown_total, separated: true)
    end
  end

  def metric(label, value, separated: false, accent: false)
    div(class: separated ? "border-l border-white/10 pl-2" : nil) do
      dt(class: "text-[.5rem] font-bold uppercase tracking-wide #{accent ? 'text-lime-300' : 'text-slate-500'}") { label }
      dd(class: "text-sm font-black tabular-nums leading-tight #{accent ? 'text-lime-300' : 'text-slate-100'}") { value }
    end
  end

  def season_stats_details
    details(class: "group mt-1.5") do
      summary(class: "flex cursor-pointer list-none items-center justify-between gap-2 text-[.6rem] font-bold uppercase tracking-wider text-slate-400 [&::-webkit-details-marker]:hidden") do
        span { "Season stats" }
        span(class: "text-slate-500 transition group-open:rotate-180", aria: { hidden: true }) { "▾" }
      end
      div(class: "mt-1") do
        render Components::Drafts::Touchdowns.new(stats: @stats.touchdowns, variant: :mobile)
        render Components::Drafts::ProductionGroups.new(groups: @stats.groups, variant: :mobile)
      end
    end
  end
end
