class AddOwnerIdsToEspnFranchises < ActiveRecord::Migration[8.1]
  def change
    add_column :espn_franchises, :owner_ids, :json, default: [], null: false
  end
end
