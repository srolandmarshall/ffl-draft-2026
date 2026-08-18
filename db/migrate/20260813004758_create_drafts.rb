class CreateDrafts < ActiveRecord::Migration[8.1]
  def change
    create_table :drafts do |t|
      t.references :league, null: false, foreign_key: true
      t.string :name, null: false
      t.string :public_id, null: false
      t.integer :status, null: false, default: 0
      t.integer :rounds, null: false, default: 16
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end


    add_index :drafts, :public_id, unique: true
  end
end
