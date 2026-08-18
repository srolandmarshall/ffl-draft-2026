class AddHeadshotUrlToPlayers < ActiveRecord::Migration[8.1]
  def change
    add_column :players, :headshot_url, :string
  end
end
