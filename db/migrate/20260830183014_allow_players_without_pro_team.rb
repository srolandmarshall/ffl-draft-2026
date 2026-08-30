class AllowPlayersWithoutProTeam < ActiveRecord::Migration[8.1]
  def change
    change_column_null :players, :pro_team, true
  end
end
