class CreateEspnTeamSeasons < ActiveRecord::Migration[8.1]
  def change
    create_table :espn_team_seasons do |t|
      t.references :espn_season, null: false, foreign_key: true
      t.references :espn_franchise, null: true, foreign_key: true
      t.integer :espn_team_id, null: false
      t.string :team_name, null: false
      t.string :team_abbreviation, null: false
      t.json :owner_ids, null: false, default: []
      t.json :owner_names, null: false, default: []
      t.integer :regular_season_rank
      t.integer :playoff_seed
      t.integer :wins, null: false, default: 0
      t.integer :losses, null: false, default: 0
      t.integer :ties, null: false, default: 0
      t.decimal :points_for, precision: 8, scale: 2
      t.decimal :points_against, precision: 8, scale: 2
      t.integer :playoff_finish
      t.integer :espn_final_rank
      t.integer :division_id

      t.timestamps
    end

    add_index :espn_team_seasons, [ :espn_season_id, :espn_team_id ], unique: true
    add_index :espn_team_seasons, [ :espn_franchise_id, :espn_season_id ], unique: true
    add_index :espn_team_seasons, [ :espn_season_id, :regular_season_rank ]
    add_index :espn_team_seasons, :playoff_finish
  end
end
