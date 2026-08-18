class AddDraftSettingsToLeagues < ActiveRecord::Migration[8.1]
  SETTINGS = {
    qb_slots: [ :integer, 1 ],
    rb_slots: [ :integer, 2 ],
    wr_slots: [ :integer, 2 ],
    te_slots: [ :integer, 1 ],
    flex_slots: [ :integer, 1 ],
    k_slots: [ :integer, 1 ],
    dst_slots: [ :integer, 1 ],
    bench_slots: [ :integer, 6 ],
    ppr: [ :decimal, 1.0 ],
    draft_type: [ :integer, 0 ],
    pick_clock_seconds: [ :integer, 90 ]
  }.freeze

  def change
    SETTINGS.each do |column, (type, default)|
      options = { null: false, default: }
      options.merge!(precision: 2, scale: 1) if type == :decimal
      add_column :leagues, column, type, **options
    end

    reversible do |direction|
      direction.up do
        SETTINGS.each_key do |column|
          execute <<~SQL.squish
            UPDATE leagues
            SET #{column} = COALESCE(
              (
                SELECT #{column}
                FROM drafts
                WHERE drafts.league_id = leagues.id
                ORDER BY drafts.created_at DESC, drafts.id DESC
                LIMIT 1
              ),
              #{column}
            )
          SQL
        end

        execute <<~SQL.squish
          UPDATE leagues
          SET roster_size = qb_slots + rb_slots + wr_slots + te_slots +
            flex_slots + k_slots + dst_slots + bench_slots
        SQL
      end
    end
  end
end
