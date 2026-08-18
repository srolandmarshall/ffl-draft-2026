class AddEspnFranchiseToEspnDraftPicks < ActiveRecord::Migration[8.1]
  def change
    add_reference :espn_draft_picks, :espn_franchise, null: true, foreign_key: true
  end
end
