class CreatePicks < ActiveRecord::Migration[8.1]
  def change
    create_table :picks do |t|
      t.references :draft, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.integer :round, null: false
      t.integer :overall_number, null: false

      t.timestamps
    end


    add_index :picks, [ :draft_id, :overall_number ], unique: true
    add_index :picks, [ :draft_id, :player_id ], unique: true
  end
end
