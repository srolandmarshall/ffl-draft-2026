# frozen_string_literal: true

class Components::LeagueHistories::FinishChart < Components::Base
  PLOT = { left: 52.0, top: 38.0, width: 650.0, height: 470.0 }.freeze

  def initialize(seasons:, tendencies:)
    @seasons = seasons
    @tendencies = tendencies.select { |tendency| tendency.finishes.any? }
    @years = seasons.map(&:season).sort.select { |year| tendencies.any? { |tendency| tendency.finishes[year] } }
  end

  def view_template
    return if @years.empty?

    @max_finish = @seasons.select { |season| @years.include?(season.season) }.map(&:team_count).max
    @default = @tendencies.find { |tendency| tendency.playoff_finishes[@years.last] == 1 } || @tendencies.first
    section(data: { controller: "finish-chart" }, class: "mb-8 overflow-hidden rounded-2xl border border-white/10 bg-slate-900 shadow-xl shadow-black/20") do
      controls
      chart
    end
  end

  private

  def controls
    div(class: "border-b border-white/5 bg-gradient-to-r from-lime-400/10 via-transparent to-violet-400/10 p-5") do
      div(class: "sm:flex sm:items-end sm:justify-between") do
        div do
          p(class: "text-xs font-bold uppercase tracking-[.18em] text-lime-400") { "The long game" }
          h2(class: "mt-1 text-2xl font-black") { "Follow one franchise through history" }
          p(class: "mt-1 text-sm text-slate-400") { "Pick a team to cut through the noise. First place lives at the top." }
        end
        p(class: "mt-3 shrink-0 text-xs font-bold text-slate-500 sm:mt-0") { "#{@years.first}–#{@years.last}" }
      end
      team_buttons
      summary_cards
    end
  end

  def team_buttons
    div(class: "mt-5 flex flex-wrap gap-2") do
      button(type: "button", class: button_classes, aria: { pressed: "false" }, data: button_data(key: "all", name: "All franchises", average: "—", best: "—", titles: "—", latest: "—")) { "All teams" }
      @tendencies.each_with_index { |tendency, index| team_button(tendency, index) }
    end
  end

  def team_button(tendency, index)
    values = tendency.finishes.values
    latest_year = @years.reverse_each.find { |year| tendency.finishes[year] }
    championships = tendency.playoff_finishes.values.count(1)
    data = button_data(
      key: tendency.franchise.id,
      name: tendency.franchise.team.name,
      color: history_team_color(index),
      average: values.sum.fdiv(values.size).round(1),
      best: values.min.ordinalize,
      titles: championships,
      latest: tendency.finishes[latest_year].ordinalize
    )
    button(type: "button", class: "flex items-center gap-2 #{button_classes}", aria: { pressed: (tendency == @default).to_s }, data:) do
      i(class: "size-3 rounded-full", style: "background: #{history_team_color(index)}")
      plain tendency.franchise.team.name
      strong(class: "text-amber-300") { " ★#{championships}" } if championships.positive?
    end
  end

  def button_data(**values)
    values.merge(finish_chart_target: "button", action: "click->finish-chart#select mouseenter->finish-chart#preview mouseleave->finish-chart#restore")
  end

  def button_classes
    "cursor-pointer rounded-full border border-white/10 px-4 py-2.5 text-xs font-bold text-slate-400 transition hover:border-white/30 aria-pressed:border-white/30 aria-pressed:bg-white/10 aria-pressed:text-white"
  end

  def summary_cards
    finishes = @default.finishes.values
    latest_year = @years.reverse_each.find { |year| @default.finishes[year] }
    div(class: "mt-5 grid gap-3 sm:grid-cols-[minmax(0,1.4fr)_repeat(4,minmax(0,1fr))]") do
      summary("Now following", @default.franchise.team.name, target: "teamName", featured: true, style: "color: #{history_team_color(@tendencies.index(@default))}")
      summary("Average finish", finishes.sum.fdiv(finishes.size).round(1), target: "average")
      summary("Best", finishes.min.ordinalize, target: "best")
      summary("Titles", @default.playoff_finishes.values.count(1), target: "titles", accent: true)
      summary("Latest", @default.finishes[latest_year].ordinalize, target: "latest")
    end
  end

  def summary(label, value, target:, featured: false, accent: false, style: nil)
    div(class: "rounded-xl border #{featured ? 'border-white/10 bg-slate-950/50' : 'border-white/5 bg-slate-950/30'} p-3") do
      span(class: "text-[.55rem] font-bold uppercase tracking-wider text-slate-600") { label }
      strong(class: "mt-1 block #{featured ? 'truncate text-lg' : 'text-xl'} #{'text-amber-300' if accent}", style:, data: { finish_chart_target: target }) { value }
    end
  end

  def chart
    div(class: "p-2 sm:p-4") do
      svg(viewBox: "0 0 840 550", class: "w-full", role: "img", aria: { label: "Historical league finishes by team and season" }) do |canvas|
        rank_grid(canvas)
        year_grid(canvas)
        @tendencies.each_with_index { |tendency, index| series(canvas, tendency, index) }
      end
    end
  end

  def rank_grid(canvas)
    1.upto(@max_finish) do |rank|
      y = PLOT[:top] + (rank - 1).fdiv(@max_finish - 1) * PLOT[:height]
      canvas.line(x1: PLOT[:left], y1: y, x2: PLOT[:left] + PLOT[:width], y2: y, stroke: "rgba(148,163,184,.12)", stroke_width: 1)
      canvas.text(x: PLOT[:left] - 14, y: y + 4, text_anchor: "middle", fill: rank == 1 ? "#a3e635" : "#64748b", font_size: 11, font_weight: 800) { rank.ordinalize }
    end
  end

  def year_grid(canvas)
    @years.each_with_index do |year, index|
      x = PLOT[:left] + (@years.one? ? PLOT[:width] / 2 : index.fdiv(@years.size - 1) * PLOT[:width])
      canvas.line(x1: x, y1: PLOT[:top], x2: x, y2: PLOT[:top] + PLOT[:height], stroke: "rgba(148,163,184,.06)", stroke_width: 1)
      canvas.text(x:, y: 535, text_anchor: "middle", fill: "#64748b", font_size: 11, font_weight: 800) { year.to_s.last(2) }
    end
  end

  def series(canvas, tendency, index)
    color = history_team_color(index)
    coordinates = finish_chart_coordinates(tendency.finishes, years: @years, width: PLOT[:width], height: PLOT[:height], max_rank: @max_finish)
    return if coordinates.empty?

    selected = tendency == @default
    canvas.g(data: { finish_chart_target: "series", key: tendency.franchise.id }, style: "opacity: #{selected ? 1 : 0.045}; transition: opacity 160ms ease") do
      points = coordinates.map { |point| "#{PLOT[:left] + point[:x]},#{PLOT[:top] + point[:y]}" }.join(" ")
      canvas.polyline(points:, fill: "none", stroke: color, stroke_width: selected ? 5 : 3, stroke_linecap: "round", stroke_linejoin: "round")
      coordinates.each { |point| chart_point(canvas, tendency, point, color) }
      last = coordinates.last
      canvas.text(x: PLOT[:left] + last[:x] + 8, y: PLOT[:top] + last[:y] + 4, fill: color, font_size: 11, font_weight: 900, style: "display: #{selected ? 'block' : 'none'}", data: { finish_chart_label: true }) { tendency.franchise.team.abbreviation }
    end
  end

  def chart_point(canvas, tendency, point, color)
    x = PLOT[:left] + point[:x]
    y = PLOT[:top] + point[:y]
    playoff_finish = tendency.playoff_finishes[point[:year]]
    canvas.circle(cx: x, cy: y, r: 7, fill: "#0f172a", stroke: "#facc15", stroke_width: 3) if playoff_finish == 1
    canvas.circle(cx: x, cy: y, r: 4, fill: color, stroke: "#0f172a", stroke_width: 2) do
      result = playoff_finish == 1 ? " · Champion" : ""
      canvas.title { "#{tendency.franchise.team.name} · #{point[:year]} · #{point[:rank].ordinalize} regular season#{result}" }
    end
  end
end
