# frozen_string_literal: true

# Run with: bin/rails runner script/profile_player_list.rb [draft_id]

draft = if ARGV.first
  Draft.find(ARGV.first)
else
  Draft.joins(:draft_entries).group(:id).order(Arel.sql("COUNT(draft_entries.id) DESC")).first
end

abort "No draft found. Seed or create a realistic draft first." unless draft

draft = Draft.includes(:league).find(draft.id)
scope = draft.available_players.includes(:league_player_scores, headshot_attachment: :blob).by_adp
available_teams = scope.reorder(:pro_team).distinct.pluck(:pro_team)
player_filters = { query: "", positions: [], teams: [] }

render_players = lambda do |players|
  ApplicationController.renderer.render(
    partial: "drafts/players",
    locals: { draft:, available_players: players, available_teams:, player_filters:, can_make_pick: false }
  )
end

measure = lambda do |players|
  html = nil
  started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  10.times { html = render_players.call(players) }
  elapsed_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 100
  { players: players.size, mean_render_ms: elapsed_ms.round(2), html_bytes: html.bytesize }
end

all_players = scope.to_a
limited_players = scope.limit(DraftsController::PLAYER_LIST_LIMIT).to_a
render_players.call(all_players)
render_players.call(limited_players)
full = measure.call(all_players)
limited = measure.call(limited_players)

puts({
  draft_id: draft.id,
  full:,
  limited:,
  render_reduction_percent: (100.0 * (1 - limited[:mean_render_ms].fdiv(full[:mean_render_ms]))).round(1),
  payload_reduction_percent: (100.0 * (1 - limited[:html_bytes].fdiv(full[:html_bytes]))).round(1)
}.inspect)
