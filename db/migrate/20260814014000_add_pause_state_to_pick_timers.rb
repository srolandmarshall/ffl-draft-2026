class AddPauseStateToPickTimers < ActiveRecord::Migration[8.1]
  def change
    add_column :drafts, :pick_timer_paused_at, :datetime
    add_column :drafts, :pick_timer_paused_seconds, :integer, null: false, default: 0
    add_column :picks, :elapsed_seconds, :integer
  end
end
