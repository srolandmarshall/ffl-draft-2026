class CreatePlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :players do |t|
      t.integer :espn_id
      t.string :name, null: false
      t.string :position, null: false
      t.string :pro_team, null: false
      t.integer :bye_week
      t.boolean :active, null: false, default: true

      t.timestamps
    end


    add_index :players, :espn_id, unique: true
    add_index :players, [ :name, :pro_team, :position ], unique: true
    add_index :players, [ :active, :position ]
  end
end
