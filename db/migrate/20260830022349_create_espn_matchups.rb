class CreateEspnMatchups < ActiveRecord::Migration[8.1]
  def change
    create_table :espn_matchups do |t|
      t.references :espn_season, null: false, foreign_key: true
      t.integer :espn_matchup_id, null: false
      t.integer :matchup_period, null: false
      t.integer :scoring_period
      t.string :playoff_tier, null: false, default: "NONE"
      t.references :home_espn_team_season, null: true, foreign_key: { to_table: :espn_team_seasons }
      t.references :away_espn_team_season, null: true, foreign_key: { to_table: :espn_team_seasons }
      t.decimal :home_points, precision: 8, scale: 2
      t.decimal :away_points, precision: 8, scale: 2
      t.decimal :margin, precision: 8, scale: 2
      t.string :winner

      t.timestamps
    end

    add_index :espn_matchups, [ :espn_season_id, :espn_matchup_id ], unique: true
    add_index :espn_matchups, [ :espn_season_id, :matchup_period ]
    add_index :espn_matchups, :playoff_tier
    add_index :espn_matchups, :margin
  end
end
