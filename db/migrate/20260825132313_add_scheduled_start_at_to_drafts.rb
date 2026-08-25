class AddScheduledStartAtToDrafts < ActiveRecord::Migration[8.1]
  def change
    add_column :drafts, :scheduled_start_at, :datetime
  end
end
