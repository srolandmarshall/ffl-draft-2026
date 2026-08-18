class CreateEspnSeasons < ActiveRecord::Migration[8.1]
  def change
    create_table :espn_seasons do |t|
      t.references :league, null: false, foreign_key: true
      t.integer :season, null: false
      t.string :name, null: false
      t.integer :team_count, null: false
      t.json :settings, null: false, default: {}
      t.json :teams, null: false, default: []
      t.datetime :synced_at, null: false

      t.timestamps
    end

    add_index :espn_seasons, [ :league_id, :season ], unique: true
  end
end
