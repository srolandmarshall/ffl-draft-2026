class CreateLeagues < ActiveRecord::Migration[8.1]
  def change
    create_table :leagues do |t|
      t.string :name, null: false
      t.integer :season, null: false
      t.integer :roster_size, null: false, default: 16

      t.timestamps
    end
  end
end
