class AddUsersAndDraftSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.integer :role, null: false, default: 0

      t.timestamps
    end
    add_index :users, :email, unique: true

    create_table :team_memberships do |t|
      t.references :team, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :team_memberships, [ :team_id, :user_id ], unique: true

    change_table :drafts, bulk: true do |t|
      t.integer :team_count, null: false, default: 10
      t.integer :qb_slots, null: false, default: 1
      t.integer :rb_slots, null: false, default: 2
      t.integer :wr_slots, null: false, default: 2
      t.integer :te_slots, null: false, default: 1
      t.integer :flex_slots, null: false, default: 1
      t.integer :k_slots, null: false, default: 1
      t.integer :dst_slots, null: false, default: 1
      t.integer :bench_slots, null: false, default: 6
      t.decimal :ppr, null: false, default: 1.0, precision: 2, scale: 1
      t.integer :draft_type, null: false, default: 0
      t.integer :pick_clock_seconds, null: false, default: 90
    end

    reversible do |direction|
      direction.up do
        execute <<~SQL.squish
          UPDATE drafts
          SET team_count = (
            SELECT COUNT(*) FROM draft_entries WHERE draft_entries.draft_id = drafts.id
          )
        SQL
      end
    end
  end
end
