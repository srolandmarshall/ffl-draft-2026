class AddDraftOrderToTeams < ActiveRecord::Migration[8.1]
  def change
    add_column :teams, :draft_order, :integer, null: false, default: 0
    add_index :teams, [ :league_id, :draft_order ]

    reversible do |direction|
      direction.up do
        execute <<~SQL.squish
          UPDATE teams
          SET draft_order = (
            SELECT COUNT(*)
            FROM teams ordered_teams
            WHERE ordered_teams.league_id = teams.league_id
              AND ordered_teams.id <= teams.id
          )
        SQL
      end
    end
  end
end
