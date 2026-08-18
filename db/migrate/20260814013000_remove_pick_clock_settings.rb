class RemovePickClockSettings < ActiveRecord::Migration[8.1]
  def change
    remove_column :drafts, :pick_clock_seconds, :integer, default: 90, null: false
    remove_column :leagues, :pick_clock_seconds, :integer, default: 90, null: false
  end
end
