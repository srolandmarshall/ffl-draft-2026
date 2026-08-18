class AddEspnTeamIdToTeams < ActiveRecord::Migration[8.1]
  def change
    add_column :teams, :espn_team_id, :integer
    add_index :teams, [ :league_id, :espn_team_id ], unique: true
  end
end
