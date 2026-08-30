# frozen_string_literal: true

class Components::LeagueStories::Ledger < Components::Base
  def initialize(seasons:)
    @seasons = seasons
  end

  def view_template
    return if @seasons.empty?

    section(class: "mb-10 overflow-hidden rounded-2xl border border-white/10 bg-slate-900 shadow-xl shadow-black/20") do
      header
      div(class: "divide-y divide-white/5") { @seasons.each { |season| row(season) } }
      footnote
    end
  end

  private

  def header
    div(class: "border-b border-white/5 bg-gradient-to-r from-amber-300/10 via-transparent to-transparent p-5") do
      p(class: "text-xs font-bold uppercase tracking-[.2em] text-amber-300") { "The ledger" }
      h2(class: "mt-1 text-2xl font-black sm:text-3xl") { "Every title, and what it cost" }
      p(class: "mt-2 text-sm text-slate-400") { "Regular-season leader on the left, the team that actually finished it on the right." }
    end
  end

  def row(season)
    div(class: "grid gap-3 p-4 sm:grid-cols-[4rem_minmax(0,1fr)_minmax(0,1fr)_auto] sm:items-center") do
      p(class: "text-lg font-black tabular-nums text-slate-500") { season.season }
      side("Best record", season.regular_season_champion, muted: true)
      side("Champion", season.champion, muted: false)
      final(season)
    end
  end

  # Leads with the franchise as it is known today so the ledger lines up with
  # the dossiers, keeping the name it actually raced under underneath.
  def side(label, team_season, muted:)
    div(class: "min-w-0") do
      p(class: "text-[10px] font-bold uppercase tracking-[.14em] text-slate-600") { label }
      p(class: "truncate text-sm font-black #{muted ? 'text-slate-400' : 'text-amber-200'}") do
        team_season&.espn_franchise&.name.presence || team_season&.team_name.presence || "—"
      end
      era_name(team_season)
    end
  end

  def era_name(team_season)
    return if team_season.blank?

    current = team_season.espn_franchise&.name
    era = team_season.team_name
    return if era.blank? || current.blank? || era.strip.casecmp?(current.strip)

    p(class: "truncate text-[11px] italic text-slate-600") { "as #{era}" }
  end

  def final(season)
    matchup = season.final
    return if matchup.blank?

    winner, loser = [ matchup.home_points, matchup.away_points ].max, [ matchup.home_points, matchup.away_points ].min
    div(class: "text-left sm:text-right") do
      p(class: "text-sm font-black tabular-nums") do
        "#{number_with_precision(winner, precision: 2)} – #{number_with_precision(loser, precision: 2)}"
      end
      p(class: "text-[10px] font-bold uppercase tracking-[.14em] #{margin_class(winner - loser)}") do
        "by #{number_with_precision(winner - loser, precision: 2)}"
      end
    end
  end

  def margin_class(margin)
    margin < 10 ? "text-rose-300" : "text-slate-600"
  end

  def footnote
    div(class: "border-t border-white/5 bg-slate-950/40 px-5 py-3") do
      p(class: "text-xs text-slate-500") do
        "Finish means regular-season seeding plus the winners' bracket. Consolation-ladder results never move a team."
      end
    end
  end
end
