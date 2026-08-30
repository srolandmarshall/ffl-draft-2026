# frozen_string_literal: true

class Components::LeagueHistories::SeasonResults < Components::Base
  def initialize(season:)
    @season = season
    @standings = season.team_seasons.select { |team_season| team_season.regular_season_rank }.sort_by(&:regular_season_rank)
    @playoffs = season.matchups.select { |matchup| matchup.playoff_tier == EspnMatchup::WINNERS_BRACKET }
  end

  def view_template
    return if @standings.empty?

    div(class: "grid border-t border-white/5 xl:grid-cols-[1.35fr_1fr]") do
      standings
      winners_bracket
    end
  end

  private

  def standings
    section(class: "min-w-0 border-b border-white/5 xl:border-b-0 xl:border-r", aria: { labelledby: standings_id }) do
      h3(id: standings_id, class: "px-5 pt-4 text-xs font-black uppercase tracking-wider text-lime-300") { "Regular-season standings" }
      div(class: "overflow-x-auto") do
        table(class: "mt-2 min-w-[620px] w-full text-left text-xs") do
          caption(class: "sr-only") { "#{@season.season} regular-season standings" }
          thead(class: "text-[.55rem] uppercase tracking-wider text-slate-600") do
            tr do
              %w[Rank Team Record PF PA Playoffs].each { |label| th(scope: "col", class: "px-3 py-2 first:pl-5 last:pr-5") { label } }
            end
          end
          tbody(class: "divide-y divide-white/5") { @standings.each { |team_season| standing_row(team_season) } }
        end
      end
    end
  end

  def standing_row(team_season)
    tr do
      td(class: "px-3 py-2 pl-5 font-black text-lime-300") { team_season.regular_season_rank.ordinalize }
      th(scope: "row", class: "px-3 py-2 font-bold") { team_season.team_name }
      td(class: table_cell_classes) { team_season.record }
      td(class: table_cell_classes) { number_with_precision(team_season.points_for, precision: 1, delimiter: ",") }
      td(class: table_cell_classes) { number_with_precision(team_season.points_against, precision: 1, delimiter: ",") }
      td(class: "#{table_cell_classes} pr-5 #{'font-bold text-amber-300' if team_season.champion?}") { team_season.playoff_result_label }
    end
  end

  def winners_bracket
    section(class: "min-w-0 p-4", aria: { labelledby: bracket_id }) do
      h3(id: bracket_id, class: "text-xs font-black uppercase tracking-wider text-amber-300") { "Winners bracket" }
      if @playoffs.empty?
        p(class: "mt-3 text-xs text-slate-500") { "No completed winners-bracket games are archived." }
      else
        div(class: "mt-3 flex gap-3 overflow-x-auto pb-2", role: "list", aria: { label: "#{@season.season} winners bracket rounds" }) do
          rounds = @playoffs.group_by(&:matchup_period).sort
          rounds.each_with_index { |(period, matchups), index| bracket_round(period, matchups, index, rounds.size) }
        end
      end
    end
  end

  def bracket_round(period, matchups, index, round_count)
    div(class: "w-48 shrink-0", role: "listitem") do
      p(class: "mb-2 text-[.55rem] font-bold uppercase tracking-wider text-slate-600") { bracket_round_label(index, round_count, period) }
      div(class: "space-y-2") { matchups.each { |matchup| bracket_matchup(matchup) } }
    end
  end

  def bracket_matchup(matchup)
    home = matchup.home_espn_team_season
    away = matchup.away_espn_team_season
    label = "#{home&.team_name || 'Bye'} #{matchup.home_points}, #{away&.team_name || 'Bye'} #{matchup.away_points}; #{matchup.winner.to_s.downcase} won"
    article(class: "rounded-lg border border-white/10 bg-slate-950/45 p-2", aria: { label: }) do
      bracket_team(home, matchup.home_points, matchup.winner == "HOME")
      bracket_team(away, matchup.away_points, matchup.winner == "AWAY")
    end
  end

  def bracket_team(team_season, points, winner)
    div(class: "flex items-center justify-between gap-2 rounded px-1 py-1 #{'bg-amber-400/10 text-amber-200' if winner}") do
      span(class: "truncate text-[.65rem] #{'font-bold' if winner}") { team_season&.team_name || "Bye" }
      strong(class: "text-[.65rem]") { number_with_precision(points, precision: 1) if points }
    end
  end

  def bracket_round_label(index, round_count, period)
    return "Finals · week #{period}" if index == round_count - 1
    return "Semifinals · week #{period}" if index == round_count - 2

    "Round #{index + 1} · week #{period}"
  end

  def standings_id = "season-#{@season.id}-standings"
  def bracket_id = "season-#{@season.id}-bracket"
  def table_cell_classes = "whitespace-nowrap px-3 py-2 text-slate-400"
end
