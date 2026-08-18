class AddDraftDataToPlayers < ActiveRecord::Migration[8.1]
  def change
    add_column :players, :ffc_id, :integer
    add_column :players, :adp, :decimal, precision: 6, scale: 2
    add_column :players, :adp_formatted, :string
    add_column :players, :adp_stdev, :decimal, precision: 6, scale: 2
    add_column :players, :adp_times_drafted, :integer
    add_column :players, :adp_updated_at, :datetime

    add_index :players, :ffc_id, unique: true
    add_index :players, :adp
  end
end
