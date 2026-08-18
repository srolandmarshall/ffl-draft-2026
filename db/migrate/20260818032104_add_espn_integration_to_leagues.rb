class AddEspnIntegrationToLeagues < ActiveRecord::Migration[8.1]
  def change
    add_column :leagues, :espn_league_id, :string
    add_column :leagues, :espn_settings, :json
    add_column :leagues, :espn_synced_at, :datetime
    add_index :leagues, [ :espn_league_id, :season ], unique: true
  end
end
