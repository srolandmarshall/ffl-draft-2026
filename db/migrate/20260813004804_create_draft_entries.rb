class CreateDraftEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :draft_entries do |t|
      t.references :draft, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.integer :position, null: false

      t.timestamps
    end


    add_index :draft_entries, [ :draft_id, :team_id ], unique: true
    add_index :draft_entries, [ :draft_id, :position ], unique: true
  end
end
