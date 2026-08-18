class CreateEspnFranchises < ActiveRecord::Migration[8.1]
  def change
    create_table :espn_franchises do |t|
      t.references :league, null: false, foreign_key: true
      t.references :team, null: true, foreign_key: true
      t.string :key, null: false
      t.string :name, null: false
      t.json :aliases, null: false, default: []

      t.timestamps
    end

    add_index :espn_franchises, [ :league_id, :key ], unique: true
  end
end
