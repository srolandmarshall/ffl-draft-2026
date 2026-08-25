# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_25_233228) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "draft_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "draft_id", null: false
    t.integer "position", null: false
    t.integer "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["draft_id", "position"], name: "index_draft_entries_on_draft_id_and_position", unique: true
    t.index ["draft_id", "team_id"], name: "index_draft_entries_on_draft_id_and_team_id", unique: true
    t.index ["draft_id"], name: "index_draft_entries_on_draft_id"
    t.index ["team_id"], name: "index_draft_entries_on_team_id"
  end

  create_table "drafts", force: :cascade do |t|
    t.integer "bench_slots", default: 6, null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "draft_type", default: 0, null: false
    t.integer "dst_slots", default: 1, null: false
    t.integer "flex_slots", default: 1, null: false
    t.integer "k_slots", default: 1, null: false
    t.integer "league_id", null: false
    t.string "name", null: false
    t.datetime "pick_timer_paused_at"
    t.integer "pick_timer_paused_seconds", default: 0, null: false
    t.decimal "ppr", precision: 2, scale: 1, default: "1.0", null: false
    t.string "public_id", null: false
    t.integer "qb_slots", default: 1, null: false
    t.integer "rb_slots", default: 2, null: false
    t.integer "rounds", default: 16, null: false
    t.datetime "scheduled_start_at"
    t.datetime "started_at"
    t.integer "status", default: 0, null: false
    t.integer "te_slots", default: 1, null: false
    t.integer "team_count", default: 10, null: false
    t.datetime "updated_at", null: false
    t.integer "wr_slots", default: 2, null: false
    t.index ["league_id"], name: "index_drafts_on_league_id"
    t.index ["public_id"], name: "index_drafts_on_public_id", unique: true
  end

  create_table "espn_draft_picks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "espn_franchise_id"
    t.integer "espn_player_id", null: false
    t.integer "espn_season_id", null: false
    t.integer "espn_team_id", null: false
    t.integer "overall_number", null: false
    t.string "player_name", null: false
    t.string "position"
    t.integer "round", null: false
    t.integer "round_pick", null: false
    t.string "team_abbreviation", null: false
    t.string "team_name", null: false
    t.datetime "updated_at", null: false
    t.index ["espn_franchise_id"], name: "index_espn_draft_picks_on_espn_franchise_id"
    t.index ["espn_season_id", "overall_number"], name: "index_espn_draft_picks_on_espn_season_id_and_overall_number", unique: true
    t.index ["espn_season_id"], name: "index_espn_draft_picks_on_espn_season_id"
  end

  create_table "espn_franchises", force: :cascade do |t|
    t.json "aliases", default: [], null: false
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.integer "league_id", null: false
    t.string "name", null: false
    t.json "owner_ids", default: [], null: false
    t.integer "team_id"
    t.datetime "updated_at", null: false
    t.index ["league_id", "key"], name: "index_espn_franchises_on_league_id_and_key", unique: true
    t.index ["league_id"], name: "index_espn_franchises_on_league_id"
    t.index ["team_id"], name: "index_espn_franchises_on_team_id"
  end

  create_table "espn_seasons", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "league_id", null: false
    t.string "name", null: false
    t.integer "season", null: false
    t.json "settings", default: {}, null: false
    t.datetime "synced_at", null: false
    t.integer "team_count", null: false
    t.json "teams", default: [], null: false
    t.datetime "updated_at", null: false
    t.index ["league_id", "season"], name: "index_espn_seasons_on_league_id_and_season", unique: true
    t.index ["league_id"], name: "index_espn_seasons_on_league_id"
  end

  create_table "league_player_scores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "league_id", null: false
    t.integer "player_id", null: false
    t.decimal "points", precision: 8, scale: 2, null: false
    t.integer "season", null: false
    t.json "stats", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["league_id", "player_id", "season"], name: "idx_on_league_id_player_id_season_a25336bb0b", unique: true
    t.index ["league_id"], name: "index_league_player_scores_on_league_id"
    t.index ["player_id"], name: "index_league_player_scores_on_player_id"
  end

  create_table "leagues", force: :cascade do |t|
    t.integer "bench_slots", default: 6, null: false
    t.datetime "created_at", null: false
    t.integer "draft_type", default: 0, null: false
    t.integer "dst_slots", default: 1, null: false
    t.string "espn_league_id"
    t.json "espn_settings"
    t.datetime "espn_synced_at"
    t.integer "flex_slots", default: 1, null: false
    t.integer "k_slots", default: 1, null: false
    t.string "name", null: false
    t.decimal "ppr", precision: 2, scale: 1, default: "1.0", null: false
    t.integer "qb_slots", default: 1, null: false
    t.integer "rb_slots", default: 2, null: false
    t.integer "roster_size", default: 16, null: false
    t.integer "season", null: false
    t.integer "te_slots", default: 1, null: false
    t.datetime "updated_at", null: false
    t.integer "wr_slots", default: 2, null: false
    t.index ["espn_league_id", "season"], name: "index_leagues_on_espn_league_id_and_season", unique: true
  end

  create_table "picks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "draft_id", null: false
    t.integer "elapsed_seconds"
    t.integer "overall_number", null: false
    t.integer "player_id", null: false
    t.integer "round", null: false
    t.integer "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["draft_id", "overall_number"], name: "index_picks_on_draft_id_and_overall_number", unique: true
    t.index ["draft_id", "player_id"], name: "index_picks_on_draft_id_and_player_id", unique: true
    t.index ["draft_id"], name: "index_picks_on_draft_id"
    t.index ["player_id"], name: "index_picks_on_player_id"
    t.index ["team_id"], name: "index_picks_on_team_id"
  end

  create_table "players", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.json "actual_stats"
    t.decimal "adp", precision: 6, scale: 2
    t.string "adp_formatted"
    t.decimal "adp_stdev", precision: 6, scale: 2
    t.integer "adp_times_drafted"
    t.datetime "adp_updated_at"
    t.integer "bye_week"
    t.datetime "created_at", null: false
    t.integer "espn_id"
    t.integer "ffc_id"
    t.string "headshot_url"
    t.string "injury_status"
    t.datetime "injury_updated_at"
    t.string "name", null: false
    t.string "position", null: false
    t.integer "position_rank"
    t.string "pro_team", null: false
    t.decimal "ranking", precision: 8, scale: 2
    t.string "ranking_source"
    t.datetime "ranking_updated_at"
    t.decimal "ranking_value", precision: 8, scale: 2
    t.boolean "rookie", default: false, null: false
    t.integer "stats_season"
    t.datetime "updated_at", null: false
    t.index ["active", "position"], name: "index_players_on_active_and_position"
    t.index ["adp"], name: "index_players_on_adp"
    t.index ["espn_id"], name: "index_players_on_espn_id", unique: true
    t.index ["ffc_id"], name: "index_players_on_ffc_id", unique: true
    t.index ["name", "pro_team", "position"], name: "index_players_on_name_and_pro_team_and_position", unique: true
    t.index ["ranking"], name: "index_players_on_ranking"
    t.index ["stats_season", "rookie"], name: "index_players_on_stats_season_and_rookie"
  end

  create_table "team_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "team_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["team_id", "user_id"], name: "index_team_memberships_on_team_id_and_user_id", unique: true
    t.index ["team_id"], name: "index_team_memberships_on_team_id"
    t.index ["user_id"], name: "index_team_memberships_on_user_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "abbreviation", null: false
    t.datetime "created_at", null: false
    t.integer "draft_order", default: 0, null: false
    t.integer "espn_team_id"
    t.integer "league_id", null: false
    t.string "name", null: false
    t.string "owner_name", null: false
    t.datetime "updated_at", null: false
    t.index ["league_id", "abbreviation"], name: "index_teams_on_league_id_and_abbreviation", unique: true
    t.index ["league_id", "draft_order"], name: "index_teams_on_league_id_and_draft_order"
    t.index ["league_id", "espn_team_id"], name: "index_teams_on_league_id_and_espn_team_id", unique: true
    t.index ["league_id", "name"], name: "index_teams_on_league_id_and_name", unique: true
    t.index ["league_id"], name: "index_teams_on_league_id"
  end

  create_table "user_emails", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["email"], name: "index_user_emails_on_email", unique: true
    t.index ["user_id"], name: "index_user_emails_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "draft_entries", "drafts"
  add_foreign_key "draft_entries", "teams"
  add_foreign_key "drafts", "leagues"
  add_foreign_key "espn_draft_picks", "espn_franchises"
  add_foreign_key "espn_draft_picks", "espn_seasons"
  add_foreign_key "espn_franchises", "leagues"
  add_foreign_key "espn_franchises", "teams"
  add_foreign_key "espn_seasons", "leagues"
  add_foreign_key "league_player_scores", "leagues"
  add_foreign_key "league_player_scores", "players"
  add_foreign_key "picks", "drafts"
  add_foreign_key "picks", "players"
  add_foreign_key "picks", "teams"
  add_foreign_key "team_memberships", "teams"
  add_foreign_key "team_memberships", "users"
  add_foreign_key "teams", "leagues"
  add_foreign_key "user_emails", "users"
end
