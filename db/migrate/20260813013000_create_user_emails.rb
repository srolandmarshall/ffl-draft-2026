class CreateUserEmails < ActiveRecord::Migration[8.1]
  def change
    create_table :user_emails do |t|
      t.references :user, null: false, foreign_key: true
      t.string :email, null: false

      t.timestamps
    end

    add_index :user_emails, :email, unique: true

    reversible do |direction|
      direction.up do
        execute <<~SQL.squish
          INSERT INTO user_emails (user_id, email, created_at, updated_at)
          SELECT id, email, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM users
        SQL
      end
    end
  end
end
