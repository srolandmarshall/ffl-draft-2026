class AddLoginCodesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :login_code_digest, :string
    add_column :users, :login_code_expires_at, :datetime
    add_column :users, :login_code_sent_at, :datetime
    add_column :users, :login_code_attempts, :integer, default: 0, null: false
  end
end
