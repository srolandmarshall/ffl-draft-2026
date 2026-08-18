class AddStatsToLeaguePlayerScores < ActiveRecord::Migration[8.1]
  def change
    add_column :league_player_scores, :stats, :json, null: false, default: {}
  end
end
