class CreateTeams < ActiveRecord::Migration[8.1]
  def change
    create_table :teams do |t|
      t.references :league, null: false, foreign_key: true
      t.string :name, null: false
      t.string :owner_name, null: false
      t.string :abbreviation, null: false

      t.timestamps
    end

    add_index :teams, [ :league_id, :name ], unique: true
    add_index :teams, [ :league_id, :abbreviation ], unique: true
  end
end
