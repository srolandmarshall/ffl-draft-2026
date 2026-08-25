module ApplicationHelper
  POSITION_BADGE_CLASSES = {
    "QB" => "border-amber-400/30 bg-amber-400/15 text-amber-200",
    "RB" => "border-emerald-400/30 bg-emerald-400/15 text-emerald-200",
    "WR" => "border-blue-400/30 bg-blue-400/15 text-blue-200",
    "TE" => "border-violet-400/30 bg-violet-400/15 text-violet-200",
    "K" => "border-pink-400/30 bg-pink-400/15 text-pink-200",
    "DST" => "border-cyan-400/30 bg-cyan-400/15 text-cyan-200"
  }.freeze

  POSITION_FILTER_CLASSES = {
    "QB" => "peer-checked:border-amber-300 peer-checked:bg-amber-400 peer-checked:text-slate-950",
    "RB" => "peer-checked:border-emerald-300 peer-checked:bg-emerald-400 peer-checked:text-slate-950",
    "WR" => "peer-checked:border-blue-300 peer-checked:bg-blue-400 peer-checked:text-slate-950",
    "TE" => "peer-checked:border-violet-300 peer-checked:bg-violet-400 peer-checked:text-slate-950",
    "K" => "peer-checked:border-pink-300 peer-checked:bg-pink-400 peer-checked:text-slate-950",
    "DST" => "peer-checked:border-cyan-300 peer-checked:bg-cyan-400 peer-checked:text-slate-950"
  }.freeze

  POSITION_CHART_COLORS = {
    "QB" => "#fbbf24",
    "RB" => "#34d399",
    "WR" => "#60a5fa",
    "TE" => "#a78bfa",
    "K" => "#f472b6",
    "DST" => "#22d3ee"
  }.freeze

  HISTORY_TEAM_COLORS = %w[
    #a3e635 #60a5fa #f472b6 #fbbf24 #34d399 #a78bfa
    #22d3ee #fb7185 #c084fc #2dd4bf #f97316 #e879f9
  ].freeze

  ESPN_NFL_TEAM_CODES = { "WAS" => "wsh" }.freeze

  def position_badge_classes(position)
    POSITION_BADGE_CLASSES.fetch(position, "border-white/20 bg-white/10 text-slate-200")
  end

  def position_filter_classes(position)
    POSITION_FILTER_CLASSES.fetch(position, "peer-checked:border-white peer-checked:bg-white peer-checked:text-slate-950")
  end

  def nfl_team_logo_url(team)
    code = ESPN_NFL_TEAM_CODES.fetch(team, team).downcase
    "https://a.espncdn.com/i/teamlogos/nfl/500/#{code}.png"
  end

  def player_headshot(player, size:)
    player.headshot.variant(resize_to_fill: [ size, size ])
  end

  def position_conic_gradient(counts)
    total = counts.values.sum
    cursor = 0.0
    segments = counts.map do |position, count|
      finish = cursor + count.fdiv(total) * 100
      segment = "#{POSITION_CHART_COLORS.fetch(position, '#94a3b8')} #{cursor.round(1)}% #{finish.round(1)}%"
      cursor = finish
      segment
    end
    "conic-gradient(#{segments.join(', ')})"
  end

  def history_team_color(index)
    HISTORY_TEAM_COLORS[index % HISTORY_TEAM_COLORS.size]
  end

  def finish_chart_coordinates(finishes, years:, width:, height:, max_rank:)
    years.filter_map do |year|
      rank = finishes[year]
      next unless rank

      x = years.one? ? width / 2.0 : years.index(year).fdiv(years.size - 1) * width
      y = max_rank == 1 ? 0 : (rank - 1).fdiv(max_rank - 1) * height
      { year:, rank:, x:, y: }
    end
  end

  def format_pick_duration(seconds)
    seconds = seconds.to_i
    minutes, remaining_seconds = seconds.divmod(60)
    hours, remaining_minutes = minutes.divmod(60)

    hours.positive? ? Kernel.format("%d:%02d:%02d", hours, remaining_minutes, remaining_seconds) : Kernel.format("%d:%02d", minutes, remaining_seconds)
  end

  def pick_duration_classes(seconds)
    case seconds.to_i
    when 90.. then "text-red-400"
    when 60...90 then "text-yellow-300"
    else "text-slate-400"
    end
  end

  def abbreviated_player_name(name)
    parts = name.to_s.split
    return name if parts.size < 2

    "#{parts.first.first}. #{parts.last}"
  end
end
