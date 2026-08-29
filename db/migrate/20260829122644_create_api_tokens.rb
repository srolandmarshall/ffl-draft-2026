class CreateApiTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :api_tokens do |t|
      t.string :token_digest
      t.datetime :expires_at
      t.datetime :last_used_at
      t.datetime :revoked_at
      t.string :label
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :api_tokens, :token_digest, unique: true
  end
end
