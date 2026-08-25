# frozen_string_literal: true

module Drafts
  class FactGenerator
    Fact = Data.define(:type, :title, :text, :value, :score, :historical, :record)
    FEATURED_POSITIONS = %w[QB RB WR TE].freeze
    FIRST_PICK_POSITIONS = %w[QB TE DST K].freeze

    def initialize(draft:, picks:, pick_elapsed_seconds: {})
      @draft = draft
      @picks = picks.sort_by(&:overall_number)
      @pick_elapsed_seconds = pick_elapsed_seconds
    end

    def call
      (current_fact_candidates + historical_fact_candidates)
        .compact
        .sort_by { |candidate| [ -candidate.score, candidate.title ] }
        .first(12)
    end

    private

    attr_reader :draft, :picks, :pick_elapsed_seconds

    def current_fact_candidates
      [
        longest_pick_fact,
        *pace_facts,
        position_run_fact,
        nfl_team_favorite_fact,
        team_collector_fact,
        *position_hoarder_facts,
        *first_position_facts,
        stack_fact,
        diverse_roster_fact,
        chaos_round_fact
      ]
    end

    def longest_pick_fact
      pick = picks.max_by { |candidate| elapsed_seconds(candidate) }
      return unless pick

      duration = elapsed_seconds(pick)
      fact(
        type: :timing,
        title: "Longest on the Clock",
        text: "#{pick.team.name} took #{human_duration(duration)} before selecting #{pick.player.name}.",
        value: human_duration(duration),
        score: 74 + [ duration / 30, 15 ].min
      )
    end

    def pace_facts
      averages = picks.group_by(&:team).to_h do |team, team_picks|
        [ team, team_picks.sum { |pick| elapsed_seconds(pick) }.fdiv(team_picks.size) ]
      end
      return [] if averages.empty?

      fastest_team, fastest_average = averages.min_by { |_team, average| average }
      slowest_team, slowest_average = averages.max_by { |_team, average| average }
      facts = [ fact(type: :timing, title: "Fastest Drafter", text: "#{fastest_team.name} averaged #{human_duration(fastest_average)} per pick.", value: human_duration(fastest_average), score: 68) ]
      if slowest_team != fastest_team
        facts << fact(type: :timing, title: "The Thinker", text: "#{slowest_team.name} used an average of #{human_duration(slowest_average)} per selection.", value: human_duration(slowest_average), score: 66)
      end
      facts
    end

    def position_run_fact
      run = biggest_position_run(picks.map { |pick| [ pick.player.position, pick ] })
      return unless run

      starter = run[:start]
      fact(
        type: :run,
        title: "Biggest Position Run",
        text: "#{starter.team.name} started a run of #{run[:count]} straight #{run[:position]} picks with #{starter.player.name}.",
        value: "#{run[:count]} #{run[:position]}s",
        score: 72 + [ run[:count] * 3, 18 ].min
      )
    end

    def nfl_team_favorite_fact
      pro_team, team_picks = picks.reject { |pick| pick.player.pro_team.blank? }.group_by { |pick| pick.player.pro_team }.max_by { |_team, grouped| grouped.size }
      return unless pro_team

      fact(type: :nfl_team, title: "NFL Team Favorite", text: "#{pro_team} led the league with #{team_picks.size} drafted players.", value: "#{team_picks.size} players", score: 61 + team_picks.size)
    end

    def team_collector_fact
      collection = picks.group_by { |pick| [ pick.team, pick.player.pro_team ] }
        .reject { |(_team, pro_team), _group| pro_team.blank? }
        .max_by { |_key, grouped| grouped.size }
      return unless collection && collection.last.size >= 2

      (team, pro_team), grouped = collection
      fact(type: :roster, title: "Team Collector", text: "#{team.name} collected #{grouped.size} players from #{pro_team}.", value: "#{grouped.size} from #{pro_team}", score: 64 + grouped.size * 2)
    end

    def position_hoarder_facts
      FEATURED_POSITIONS.filter_map do |position|
        team, grouped = picks.select { |pick| pick.player.position == position }.group_by(&:team).max_by { |_candidate, selected| selected.size }
        next unless team && grouped.size >= 2

        fact(type: :roster, title: "#{position} Hoarder", text: "#{team.name} drafted a league-high #{grouped.size} #{position}s.", value: grouped.size.to_s, score: 52 + grouped.size * 2)
      end
    end

    def first_position_facts
      FIRST_PICK_POSITIONS.filter_map do |position|
        pick = picks.find { |candidate| candidate.player.position == position }
        next unless pick

        fact(type: :milestone, title: "First #{position}", text: "#{pick.team.name} opened the #{position} market with #{pick.player.name} at pick #{pick.overall_number}.", value: "Pick #{pick.overall_number}", score: 48 + [ pick.overall_number / 5, 10 ].min)
      end
    end

    def stack_fact
      stack = picks.group_by { |pick| [ pick.team, pick.player.pro_team ] }.filter_map do |(team, pro_team), grouped|
        positions = grouped.map { |pick| pick.player.position }
        next unless positions.include?("QB") && (positions & %w[WR TE]).any?

        [ team, pro_team, grouped ]
      end.max_by { |_team, _pro_team, grouped| grouped.size }
      return unless stack

      team, pro_team, grouped = stack
      names = grouped.map { |pick| pick.player.name }.to_sentence
      fact(type: :stack, title: "Stack City", text: "#{team.name} built a #{pro_team} stack with #{names}.", value: "#{grouped.size}-player stack", score: 78 + grouped.size * 3)
    end

    def diverse_roster_fact
      team, team_picks = picks.group_by(&:team).max_by { |_candidate, grouped| grouped.map { |pick| pick.player.pro_team }.compact.uniq.size }
      return unless team

      count = team_picks.map { |pick| pick.player.pro_team }.compact.uniq.size
      fact(type: :roster, title: "Most Diverse Roster", text: "#{team.name}'s players represented #{count} different NFL teams.", value: "#{count} NFL teams", score: 57 + count)
    end

    def chaos_round_fact
      round, round_picks = picks.group_by(&:round).max_by do |_candidate, grouped|
        grouped.map { |pick| pick.player.position }.uniq.size * 3 + grouped.group_by { |pick| pick.player.pro_team }.values.map(&:size).max.to_i
      end
      return unless round

      positions = round_picks.map { |pick| pick.player.position }.uniq
      favorite_team, favorite_count = round_picks.map { |pick| pick.player.pro_team }.compact.tally.max_by { |_team, count| count }
      context = favorite_count.to_i >= 2 ? " #{favorite_count} came from #{favorite_team}." : ""
      fact(type: :round, title: "Round of Chaos", text: "Round #{round} mixed #{positions.size} positions across #{round_picks.size} picks.#{context}", value: "Round #{round}", score: 55 + positions.size * 2 + favorite_count.to_i)
    end

    def historical_fact_candidates
      return [] if historical_picks.empty?

      [ my_guy_fact, journeyman_fact, movement_fact, deja_vu_fact, position_run_record_fact, first_qb_record_fact ]
    end

    def my_guy_fact
      repeat = picks.filter_map do |pick|
        franchise = franchises_by_team[pick.team_id]
        next unless franchise

        matches = history_for(pick.player.name).select { |historical_pick| historical_pick.espn_franchise_id == franchise.id }
        [ pick, matches ] if matches.any?
      end.max_by { |_pick, matches| matches.size }
      return unless repeat

      pick, matches = repeat
      fact(type: :history, title: "My Guy", text: "#{pick.team.name} came back for #{pick.player.name} after drafting them #{matches.size} prior #{'time'.pluralize(matches.size)}.", value: "#{matches.size + 1} drafts", score: 86 + matches.size * 4, historical: true)
    end

    def journeyman_fact
      journey = picks.map(&:player).uniq.filter_map do |player|
        teams = history_for(player.name).map { |pick| pick.espn_franchise_id || "team:#{pick.team_name}" }.uniq
        [ player, teams ] if teams.size >= 2
      end.max_by { |_player, teams| teams.size }
      return unless journey

      player, teams = journey
      fact(type: :history, title: "League Journeyman", text: "#{player.name} has now appeared on rosters tied to #{teams.size} different league managers across the available history.", value: "#{teams.size} managers", score: 76 + teams.size * 3, historical: true)
    end

    def movement_fact
      movement = picks.filter_map do |pick|
        previous = history_for(pick.player.name).max_by { |historical_pick| historical_pick.espn_season.season }
        next unless previous

        difference = previous.overall_number - pick.overall_number
        [ pick, previous, difference ] if difference.abs >= 5
      end.max_by { |_pick, _previous, difference| difference.abs }
      return unless movement

      pick, previous, difference = movement
      direction = difference.positive? ? "Rocket" : "Faller"
      wording = difference.positive? ? "earlier" : "later"
      fact(type: :history, title: direction, text: "#{pick.player.name} moved #{difference.abs} picks #{wording} than in #{previous.espn_season.season}.", value: "#{difference.abs} picks", score: 72 + [ difference.abs / 3, 16 ].min, historical: true)
    end

    def deja_vu_fact
      match = picks.filter_map do |pick|
        franchise = franchises_by_team[pick.team_id]
        next unless franchise

        previous = history_for(pick.player.name).select { |historical_pick| historical_pick.espn_franchise_id == franchise.id }
          .min_by { |historical_pick| (historical_pick.overall_number - pick.overall_number).abs }
        next unless previous && (previous.overall_number - pick.overall_number).abs <= 3

        [ pick, previous ]
      end.first
      return unless match

      pick, previous = match
      fact(type: :history, title: "Déjà Vu", text: "#{pick.team.name} drafted #{pick.player.name} within three slots of where it did in #{previous.espn_season.season}.", value: "Picks #{previous.overall_number} & #{pick.overall_number}", score: 88, historical: true)
    end

    def position_run_record_fact
      current = biggest_position_run(picks.map { |pick| [ pick.player.position, pick ] })
      historical_max = historical_seasons.filter_map do |season|
        biggest_position_run(season.draft_picks.map { |pick| [ pick.position, pick ] })&.fetch(:count)
      end.max
      return unless current && historical_max && current[:count] > historical_max

      fact(type: :record, title: "League Record Run", text: "This draft's run of #{current[:count]} straight #{current[:position]}s beat the prior record of #{historical_max}.", value: "#{current[:count]} straight", score: 100, historical: true, record: true)
    end

    def first_qb_record_fact
      current = picks.find { |pick| pick.player.position == "QB" }
      historical_firsts = historical_seasons.filter_map { |season| season.draft_picks.find { |pick| pick.position == "QB" } }
      return unless current && historical_firsts.any?

      earliest = historical_firsts.min_by(&:overall_number)
      latest = historical_firsts.max_by(&:overall_number)
      if current.overall_number < earliest.overall_number
        fact(type: :record, title: "Earliest QB Record", text: "#{current.player.name} at pick #{current.overall_number} is the earliest first quarterback in the available league history.", value: "Pick #{current.overall_number}", score: 98, historical: true, record: true)
      elsif current.overall_number > latest.overall_number
        fact(type: :record, title: "Latest QB Record", text: "The league waited until pick #{current.overall_number} for #{current.player.name}, a new latest-first-QB mark.", value: "Pick #{current.overall_number}", score: 98, historical: true, record: true)
      end
    end

    def biggest_position_run(sequence)
      best = nil
      current = nil
      sequence.each do |position, source|
        current = current && current[:position] == position ? current.merge(count: current[:count] + 1) : { position:, count: 1, start: source }
        best = current if best.nil? || current[:count] > best[:count]
      end
      best
    end

    def elapsed_seconds(pick)
      pick.elapsed_seconds || pick_elapsed_seconds[pick.id] || pick_elapsed_seconds[pick.id.to_s] || 0
    end

    def human_duration(seconds)
      total = seconds.round
      format("%d:%02d", total / 60, total % 60)
    end

    def historical_seasons
      @historical_seasons ||= draft.league.espn_seasons.where("season < ?", draft.league.season).includes(draft_picks: :espn_franchise).to_a
    end

    def historical_picks
      @historical_picks ||= historical_seasons.flat_map(&:draft_picks)
    end

    def history_by_name
      @history_by_name ||= historical_picks.group_by { |pick| pick.player_name.downcase }
    end

    def history_for(player_name)
      history_by_name.fetch(player_name.downcase, [])
    end

    def franchises_by_team
      @franchises_by_team ||= draft.league.espn_franchises.where.not(team_id: nil).index_by(&:team_id)
    end

    def fact(type:, title:, text:, value:, score:, historical: false, record: false)
      Fact.new(type:, title:, text:, value:, score:, historical:, record:)
    end
  end
end
