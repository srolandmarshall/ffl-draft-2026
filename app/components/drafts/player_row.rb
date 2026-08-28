# frozen_string_literal: true

# One player as a row in the desktop draft table.
#
# The mobile card renders the same player from the same stats; only the layout differs.
class Components::Drafts::PlayerRow < Components::Base
  def initialize(draft:, player:, stats:, can_make_pick:)
    @draft = draft
    @player = player
    @stats = stats
    @can_make_pick = can_make_pick
  end

  def view_template
    tr(
      class: "#{position_surface_classes(@player.position)} transition hover:brightness-110",
      data: { draft_player_id: @player.id }
    ) do
      td(class: "px-3 py-2.5") { render Components::Drafts::PlayerIdentity.new(player: @player, variant: :desktop) }
      numeric_cell("text-center", "font-bold tabular-nums text-slate-300") { @stats.bye_week }
      numeric_cell("text-right", "text-base font-black tabular-nums text-lime-400") { @stats.points }
      numeric_cell("text-center", "font-bold tabular-nums text-slate-200") { @stats.games }
      td(class: "px-2 py-2.5 text-center") { render Components::Drafts::Touchdowns.new(stats: @stats.touchdowns) }
      td(class: "px-3 py-2.5") { render Components::Drafts::ProductionGroups.new(groups: @stats.groups) }
      td(class: "px-3 py-2.5 text-right") do
        render Components::Drafts::Action.new(draft: @draft, player: @player, can_make_pick: @can_make_pick)
      end
    end
  end

  private

  def numeric_cell(alignment, value_classes, &value)
    td(class: "px-2 py-2.5 #{alignment}") { span(class: value_classes, &value) }
  end
end
