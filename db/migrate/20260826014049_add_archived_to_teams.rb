class AddArchivedToTeams < ActiveRecord::Migration[8.1]
  def change
    add_column :teams, :archived, :boolean, default: false, null: false
  end
end
