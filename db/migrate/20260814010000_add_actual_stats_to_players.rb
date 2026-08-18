class AddActualStatsToPlayers < ActiveRecord::Migration[8.1]
  def change
    add_column :players, :actual_stats, :json
    add_column :players, :stats_season, :integer
    add_column :players, :rookie, :boolean, null: false, default: false
    add_index :players, [ :stats_season, :rookie ]
  end
end
