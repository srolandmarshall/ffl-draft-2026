module Drafts
  class HistoricalTendencies
    RoundSignature = Data.define(:round, :position, :count, :total)
    ChaosRound = Data.define(:round, :position_count)
    PositionRun = Data.define(:position, :length, :season)
    Tendency = Data.define(
      :franchise, :seasons, :pick_count, :repeat_player_name, :repeat_player_count,
      :position_counts, :round_position_counts, :average_first_rounds, :finishes, :playoff_finishes,
      :signature_round, :chaos_round, :longest_position_run
    )

    def initialize(franchises:, seasons:)
      @franchises = franchises
      @seasons = seasons
    end

    def call
      season_ids = seasons.map(&:id)
      franchises.filter_map do |franchise|
        picks = franchise.draft_picks.select { |pick| pick.espn_season_id.in?(season_ids) }
        build_tendency(franchise, picks) if picks.any?
      end
    end

    private

    attr_reader :franchises, :seasons

    def build_tendency(franchise, picks)
      repeat_name, repeat_count = repeat_player(picks)
      round_counts = picks.group_by(&:round).sort.to_h do |round, round_picks|
        [ round, position_counts(round_picks) ]
      end
      season_count = picks.map { |pick| pick.espn_season.season }.uniq.size
      Tendency.new(
        franchise:,
        seasons: season_count,
        pick_count: picks.size,
        repeat_player_name: repeat_name,
        repeat_player_count: repeat_count,
        position_counts: position_counts(picks),
        round_position_counts: round_counts,
        average_first_rounds: average_first_rounds(picks),
        finishes: finishes_for(franchise),
        playoff_finishes: playoff_finishes_for(franchise),
        signature_round: signature_round(round_counts, season_count),
        chaos_round: chaos_round(round_counts),
        longest_position_run: longest_position_run(picks)
      )
    end

    def position_counts(picks)
      picks.filter_map(&:position).tally.sort_by { |position, count| [ -count, position ] }.to_h
    end

    def finishes_for(franchise)
      season_ids = seasons.index_by(&:id)
      franchise.team_seasons.filter_map do |team_season|
        season = season_ids[team_season.espn_season_id]
        rank = team_season.regular_season_rank.to_i
        [ season.season, rank ] if season && rank.positive?
      end.to_h
    end

    def playoff_finishes_for(franchise)
      season_ids = seasons.index_by(&:id)
      franchise.team_seasons.filter_map do |team_season|
        season = season_ids[team_season.espn_season_id]
        [ season.season, team_season.playoff_finish ] if season && team_season.playoff_finish
      end.to_h
    end

    def repeat_player(picks)
      group = picks.group_by(&:espn_player_id).values.select { |player_picks| player_picks.size > 1 }.max_by(&:size)
      [ group&.first&.player_name, group&.size.to_i ]
    end

    def average_first_rounds(picks)
      first_rounds = Hash.new { |hash, position| hash[position] = [] }
      picks.group_by(&:espn_season_id).each_value do |season_picks|
        season_picks.group_by(&:position).each do |position, position_picks|
          first_rounds[position] << position_picks.map(&:round).min if position
        end
      end
      first_rounds.transform_values { |rounds| rounds.sum.fdiv(rounds.size).round(1) }
    end

    def signature_round(round_counts, season_count)
      minimum_sample = [ 3, (season_count / 2.0).ceil ].max
      candidates = round_counts.filter_map do |round, counts|
        position, count = counts.first
        total = counts.values.sum
        RoundSignature.new(round:, position:, count:, total:) if total >= minimum_sample
      end
      candidates.max_by { |signature| [ signature.count.fdiv(signature.total), signature.total, -signature.round ] }
    end

    def chaos_round(round_counts)
      round, counts = round_counts.max_by do |candidate_round, candidate_counts|
        total = candidate_counts.values.sum
        [ candidate_counts.size, 1 - candidate_counts.values.max.fdiv(total), -candidate_round ]
      end
      ChaosRound.new(round:, position_count: counts.size) if round
    end

    def longest_position_run(picks)
      runs = picks.group_by(&:espn_season).flat_map do |season, season_picks|
        current_position = nil
        current_length = 0
        previous_round = nil
        season_picks.sort_by(&:round).map do |pick|
          if pick.position == current_position && pick.round == previous_round.to_i + 1
            current_length += 1
          else
            current_position = pick.position
            current_length = 1
          end
          previous_round = pick.round
          PositionRun.new(position: current_position, length: current_length, season: season.season)
        end
      end
      runs.compact.max_by { |run| [ run.length, -run.season ] }
    end
  end
end
