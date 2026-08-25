class AddInjuryStatusToPlayers < ActiveRecord::Migration[8.1]
  def change
    add_column :players, :injury_status, :string
    add_column :players, :injury_updated_at, :datetime
  end
end
