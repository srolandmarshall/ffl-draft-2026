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

  POSITION_SURFACE_CLASSES = {
    "QB" => "border-amber-400/40 bg-amber-400/20",
    "RB" => "border-emerald-400/40 bg-emerald-400/20",
    "WR" => "border-blue-400/40 bg-blue-400/20",
    "TE" => "border-violet-400/40 bg-violet-400/20",
    "K" => "border-pink-400/40 bg-pink-400/20",
    "DST" => "border-cyan-400/40 bg-cyan-400/20"
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

  # Logos never render above 36 CSS pixels, so 80px covers them at 2x.
  NFL_TEAM_LOGO_SIZE = 80

  # Portraits and logos are decorative and sit below the fold, so they share loading
  # hints that let the document and controls become interactive first.
  LAZY_IMAGE_ATTRIBUTES = { alt: "", loading: "lazy", decoding: "async", fetchpriority: "low" }.freeze

  def position_badge_classes(position)
    POSITION_BADGE_CLASSES.fetch(position, "border-white/20 bg-white/10 text-slate-200")
  end

  def position_filter_classes(position)
    POSITION_FILTER_CLASSES.fetch(position, "peer-checked:border-white peer-checked:bg-white peer-checked:text-slate-950")
  end

  def position_surface_classes(position)
    POSITION_SURFACE_CLASSES.fetch(position, "border-white/20 bg-white/10")
  end

  # ESPN only publishes these at 500px, where a single logo runs 30-130KB. Its combiner
  # endpoint resizes on the CDN, bringing each one down to roughly 3KB.
  def nfl_team_logo_url(team, size: NFL_TEAM_LOGO_SIZE)
    code = ESPN_NFL_TEAM_CODES.fetch(team, team).downcase
    "https://a.espncdn.com/combiner/i?img=/i/teamlogos/nfl/500/#{code}.png&w=#{size}&h=#{size}"
  end

  def player_headshot(player)
    player.headshot.variant(:portrait)
  end

  # With a CDN configured, a portrait comes from it or it is not rendered at all. A variant
  # that has not been generated yet has no key to link to, so fall through to the position
  # letter rather than sending the read back through the app. Preprocessing means that gap
  # lasts only until the transform job finishes; the backfill task closes it for headshots
  # attached before preprocessing existed.
  def player_portrait?(player)
    return true if player.position == "DST"
    return false unless player.headshot.attached?

    Rails.configuration.x.cdn_host.blank? || player_headshot(player).key.present?
  end

  # Serving portraits through the Active Storage proxy costs a Puma thread per image while
  # the app streams the bytes back out of S3, so a cold draft room queues its own page and
  # Turbo requests behind them. The generated variant is immutable, so point the browser at
  # the CDN instead. The proxy is only reachable here with no CDN configured, which is
  # development and test; `player_portrait?` gates the rest.
  def player_portrait_url(player)
    return nfl_team_logo_url(player.pro_team) if player.position == "DST"

    variant = player_headshot(player)
    cdn_asset_url(variant.key) || url_for(variant)
  end

  def cdn_asset_url(key)
    host = Rails.configuration.x.cdn_host
    return if key.blank? || host.blank?

    "#{host.start_with?('http') ? host : "https://#{host}"}/#{key}"
  end

  # Centralizing the image attributes keeps every placement on one URL per player, which
  # is what lets the browser reuse a single download for the mobile and desktop markup.
  def player_portrait_attributes(player, classes:, **overrides)
    fit = player.position == "DST" ? "object-contain p-0.5" : "object-cover object-top"
    LAZY_IMAGE_ATTRIBUTES.merge(
      src: player_portrait_url(player),
      title: (player.pro_team if player.position == "DST"),
      class: [ classes, fit ].compact.join(" "),
      **overrides
    )
  end

  def nfl_team_logo_attributes(team, classes:, **overrides)
    LAZY_IMAGE_ATTRIBUTES.merge(src: nfl_team_logo_url(team), title: team, class: classes, **overrides)
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
