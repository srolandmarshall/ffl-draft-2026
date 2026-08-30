module Leagues
  # Joins archived draft picks to end-of-season scoring so a pick can be judged
  # against what the player actually did. Only possible since historical
  # league_player_scores exist for every synced season.
  class DraftValue
    Pick = Data.define(
      :season, :overall_pick, :round, :player_name, :position,
      :franchise, :team_name, :points, :position_rank, :position_draft_rank
    ) do
      # How many places the player beat (positive) or missed (negative) the
      # positional slot his draft cost implied. The Nth back off the board is
      # expected to finish RB N.
      def value_over_draft
        return unless position_draft_rank && position_rank

        position_draft_rank - position_rank
      end
    end

    MIN_POSITION_PICKS = 3

    def self.call(league) = new(league).call

    def initialize(league)
      @league = league
    end

    def call = picks

    # Picks that most outperformed the positional slot they were drafted at.
    def steals(limit: 10)
      ranked.select { |pick| pick.value_over_draft.to_i.positive? }
        .max_by(limit) { |pick| pick.value_over_draft }
    end

    # Picks inside the first few rounds that badly missed.
    def busts(limit: 10, max_round: 3)
      ranked.select { |pick| pick.round <= max_round && pick.value_over_draft.to_i.negative? }
        .min_by(limit) { |pick| pick.value_over_draft }
    end

    def for_franchise(franchise)
      ranked.select { |pick| pick.franchise == franchise }
    end

    private

    attr_reader :league

    # Every pick that resolved to a player we have a season score for.
    def picks
      @picks ||= begin
        seasons = league.espn_seasons.includes(draft_picks: :espn_franchise).to_a
        scores = score_index
        seasons.flat_map do |season|
          ranks = position_ranks(scores[season.season] || {})
          season.draft_picks.filter_map do |pick|
            score = scores.dig(season.season, pick.espn_player_id.to_i)
            next unless score

            Pick.new(
              season: season.season, overall_pick: pick.overall_number, round: pick.round,
              player_name: pick.player_name, position: pick.position,
              franchise: pick.espn_franchise, team_name: pick.team_name,
              points: score.points, position_rank: ranks[pick.espn_player_id.to_i],
              position_draft_rank: nil
            )
          end
        end
      end
    end

    # Picks with both a finish rank and the positional rank their draft slot implied.
    def ranked
      @ranked ||= picks.group_by { |pick| [ pick.season, pick.position ] }.flat_map do |(_season, position), group|
        next [] if position.blank? || group.size < MIN_POSITION_PICKS

        group.sort_by(&:overall_pick).each_with_index.map do |pick, index|
          pick.with(position_draft_rank: index + 1)
        end
      end.select(&:position_rank)
    end

    def score_index
      @score_index ||= league.league_player_scores.includes(:player).group_by(&:season).transform_values do |scores|
        scores.index_by { |score| score.player.espn_id }
      end
    end

    # Positional finish rank for one season, keyed by ESPN player id.
    def position_ranks(scores_by_espn_id)
      scores_by_espn_id.values.group_by { |score| score.player.position }.flat_map do |_position, scores|
        scores.sort_by { |score| -score.points }.each_with_index.map { |score, index| [ score.player.espn_id, index + 1 ] }
      end.to_h
    end
  end
end
