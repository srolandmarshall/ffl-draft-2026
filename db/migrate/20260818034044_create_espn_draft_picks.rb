class CreateEspnDraftPicks < ActiveRecord::Migration[8.1]
  def change
    create_table :espn_draft_picks do |t|
      t.references :espn_season, null: false, foreign_key: true
      t.integer :overall_number, null: false
      t.integer :round, null: false
      t.integer :round_pick, null: false
      t.integer :espn_team_id, null: false
      t.string :team_name, null: false
      t.string :team_abbreviation, null: false
      t.integer :espn_player_id, null: false
      t.string :player_name, null: false
      t.string :position

      t.timestamps
    end


    add_index :espn_draft_picks, [ :espn_season_id, :overall_number ], unique: true
  end
end
