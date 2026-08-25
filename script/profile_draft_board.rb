# frozen_string_literal: true

# Run with: bin/rails runner script/profile_draft_board.rb [draft_id]

draft_id = ARGV.first
draft = if draft_id
  Draft.find(draft_id)
else
  Draft.joins(:draft_entries).group(:id).order(Arel.sql("COUNT(draft_entries.id) DESC")).first
end

abort "No draft found. Seed or create a realistic draft first." unless draft

draft = Draft.includes(draft_entries: :team).find(draft.id)
picks = draft.picks.includes(:team, player: { headshot_attachment: :blob }).to_a
elapsed_seconds = picks.to_h { |pick| [ pick.id, pick.elapsed_seconds.to_i ] }

measure = lambda do |iterations, &block|
  started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  iterations.times(&block)
  ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1_000 / iterations).round(2)
end

board_html = nil
board_ms = measure.call(10) do
  board_html = ApplicationController.renderer.render(
    Components::Drafts::Board.new(draft:, picks:, pick_elapsed_seconds: elapsed_seconds),
    layout: false
  )
end

result = {
  draft_id: draft.id,
  teams: draft.draft_entries.size,
  rounds: draft.rounds,
  picks: picks.size,
  initial_board_mean_ms: board_ms,
  initial_board_bytes: board_html.bytesize
}

if (latest_pick = picks.last) && latest_pick.overall_number < draft.total_picks
  broadcast = Drafts::BroadcastPick.new(latest_pick)
  picked_html = next_html = nil
  live_update_ms = measure.call(20) do
    picked_html = broadcast.send(:board_cell_html, latest_pick.overall_number, pick: broadcast.send(:broadcast_pick))
    next_html = broadcast.send(:board_cell_html, latest_pick.overall_number + 1)
  end
  live_bytes = picked_html.bytesize + next_html.bytesize
  result.merge!(
    live_cells_mean_ms: live_update_ms,
    live_cells_bytes: live_bytes,
    live_payload_reduction_percent: (100.0 * (1 - live_bytes.fdiv(board_html.bytesize))).round(1)
  )
end

puts result.inspect
