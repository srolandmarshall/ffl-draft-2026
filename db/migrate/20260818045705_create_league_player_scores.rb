class CreateLeaguePlayerScores < ActiveRecord::Migration[8.1]
  def change
    create_table :league_player_scores do |t|
      t.references :league, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.integer :season, null: false
      t.decimal :points, precision: 8, scale: 2, null: false

      t.timestamps
    end

    add_index :league_player_scores, [ :league_id, :player_id, :season ], unique: true
  end
end
