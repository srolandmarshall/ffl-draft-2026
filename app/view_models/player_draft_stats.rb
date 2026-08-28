# frozen_string_literal: true

# The prior-season numbers the draft room shows for one player.
#
# The list renders every player twice - a desktop table row and a mobile card - so resolving
# these once per player is what keeps the two breakpoints from drifting apart, and what keeps
# a second pass over the (preloaded) league scores off the render path.
#
# Defenses score under the league's own ESPN rules rather than the synced per-player stat
# lines, so their production and touchdowns come off the league score instead of the player.
class PlayerDraftStats
  NONE = "—"

  attr_reader :player, :fantasy_points, :groups, :touchdowns

  def initialize(draft, player)
    @player = player
    league_score = draft.prior_season_score_for(player)
    @fantasy_points = league_score&.points
    @groups = defense? ? (league_score&.dst_stat_groups || []) : player.draft_stat_groups
    @touchdowns = defense? ? (league_score&.dst_touchdown_stats || []) : player.draft_touchdown_stats
  end

  def points
    return NONE unless fantasy_points

    ActiveSupport::NumberHelper.number_to_rounded(fantasy_points, precision: 1)
  end

  def touchdown_total
    return NONE if touchdowns.empty?

    touchdowns.sum { |_label, value| value }
  end

  def bye_week = player.bye_week || NONE
  def games = player.draft_games || NONE

  private

  def defense? = player.position == "DST"
end
