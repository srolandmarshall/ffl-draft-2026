class AddRankingToPlayers < ActiveRecord::Migration[8.1]
  def change
    add_column :players, :ranking, :decimal, precision: 8, scale: 2
    add_column :players, :ranking_source, :string
    add_column :players, :position_rank, :integer
    add_column :players, :ranking_value, :decimal, precision: 8, scale: 2
    add_column :players, :ranking_updated_at, :datetime
    add_index :players, :ranking

    reversible do |direction|
      direction.up do
        execute <<~SQL.squish
          UPDATE players
          SET ranking = adp,
              ranking_source = 'fantasy_football_calculator',
              ranking_updated_at = adp_updated_at
          WHERE adp IS NOT NULL
        SQL
      end
    end
  end
end
