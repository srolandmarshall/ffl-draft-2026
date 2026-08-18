require "test_helper"

class Admin::EspnSettingsSyncsControllerTest < ActionDispatch::IntegrationTest
  SETTINGS_PAYLOAD = {
    "seasonId" => 2026,
    "status" => { "previousSeasons" => [] },
    "members" => [ { "id" => "owner-1", "displayName" => "Riley" } ],
    "teams" => [
      { "id" => 7, "abbrev" => "RED", "name" => "Red Hawks", "owners" => [ "owner-1" ], "rankCalculatedFinal" => 1 },
      { "id" => 8, "abbrev" => "NEW", "name" => "New ESPN Team", "owners" => [], "rankCalculatedFinal" => 2 }
    ],
    "draftDetail" => {
      "drafted" => true,
      "picks" => [ { "teamId" => 7, "playerId" => 77_001, "roundId" => 1, "roundPickNumber" => 1 } ]
    },
    "settings" => {
      "name" => "ESPN Test League",
      "size" => 12,
      "draftSettings" => { "type" => 1 },
      "rosterSettings" => {
        "lineupSlotCounts" => {
          "0" => 1, "2" => 2, "4" => 3, "6" => 1, "16" => 1,
          "17" => 1, "20" => 6, "21" => 2, "23" => 2
        }
      },
      "scoringSettings" => {
        "scoringItems" => [
          { "statId" => 53, "points" => 0.5 },
          { "statId" => 102, "points" => 6 },
          { "statId" => 999, "points" => 0 }
        ]
      },
      "acquisitionSettings" => { "acquisitionBudget" => 100, "acquisitionLimit" => -1, "waiverHours" => 24 },
      "tradeSettings" => { "max" => -1 }
    }
  }.freeze

  test "ESPN client returns a league settings object" do
    requested_uri = nil
    response = Struct.new(:code, :body).new("200", SETTINGS_PAYLOAD.to_json)
    client = DataSources::Espn::Client.new(fetcher: ->(uri) { requested_uri = uri; response })

    settings = client.fetch_league_settings(year: 2026, league_id: 123_456)

    assert_instance_of DataSources::Espn::LeagueSettings, settings
    assert_equal "/apis/v3/games/ffl/seasons/2026/segments/0/leagues/123456", requested_uri.path
    assert_equal "view=mSettings", requested_uri.query
  end

  test "ESPN client returns actual player totals calculated with league scoring" do
    requested_uri = nil
    payload = {
      "players" => [
        {
          "player" => {
            "id" => 77_001,
            "stats" => [
              { "seasonId" => 2025, "scoringPeriodId" => 0, "statSourceId" => 1, "statSplitTypeId" => 0, "appliedTotal" => 400 },
              { "seasonId" => 2025, "scoringPeriodId" => 0, "statSourceId" => 0, "statSplitTypeId" => 0, "appliedTotal" => 321.45, "stats" => { "99" => 55 } }
            ]
          }
        }
      ]
    }
    response = Struct.new(:code, :body).new("200", payload.to_json)
    client = DataSources::Espn::Client.new(fetcher: ->(uri) { requested_uri = uri; response })

    scores = client.fetch_player_scores(year: 2025, league_id: 123_456)

    assert_equal 77_001, scores.first.espn_id
    assert_equal BigDecimal("321.45"), scores.first.points
    assert_equal 55, scores.first.stats.fetch("99")
    assert_equal "kona_player_info", URI.decode_www_form(requested_uri.query).to_h.fetch("view")
  end

  test "settings object exposes domain values instead of its ESPN JSON shape" do
    settings = DataSources::Espn::LeagueSettings.from_payload(SETTINGS_PAYLOAD)

    assert_equal "ESPN Test League", settings.league_name
    assert_equal 12, settings.team_count
    assert_equal 0.5, settings.draft_defaults[:ppr]
    assert_equal 3, settings.draft_defaults[:wr_slots]
    assert_equal 2, settings.draft_defaults[:flex_slots]
    assert_equal 6, settings.draft_defaults[:bench_slots]
    assert_equal :snake, settings.draft_defaults[:draft_type]
    assert_equal({ "QB" => 1, "RB" => 2, "WR" => 3, "TE" => 1, "FLEX" => 2, "K" => 1, "DST" => 1, "Bench" => 6, "IR" => 2 }, settings.lineup_rules)
    assert_includes settings.scoring_rules.map(&:label), "Reception"
    assert_includes settings.scoring_rules.map(&:label), "Punt return touchdown"
    assert_not_includes settings.scoring_rules.map(&:label), "ESPN stat #999"
    assert_equal "FAAB budget", settings.league_rules.first.label
    assert_not_includes settings.league_rules.map(&:label), "Season acquisition limit"
    assert_not_includes settings.league_rules.map(&:label), "Season trade limit"
  end

  test "commissioner imports ESPN rules into league defaults" do
    league = leagues(:one)
    league.update!(espn_league_id: "123456")
    original_order = teams(:one).draft_order
    snapshot = DataSources::Espn::LeagueSnapshot.from_payload(SETTINGS_PAYLOAD)
    client = Object.new
    client.define_singleton_method(:fetch_league_snapshot) { |**| snapshot }
    client.define_singleton_method(:fetch_players) do |**|
      [ { "id" => 77_001, "fullName" => "Josh Allen", "defaultPositionId" => 1 } ]
    end
    client.define_singleton_method(:fetch_player_scores) do |**|
      [ DataSources::Espn::Client::PlayerScore.new(espn_id: 1, points: BigDecimal("321.45"), stats: {}) ]
    end
    sign_in_as users(:commissioner)

    original_constructor = DataSources::Espn::Client.method(:new)
    DataSources::Espn::Client.define_singleton_method(:new) { |**| client }
    begin
      post admin_league_espn_settings_sync_path(league)
    ensure
      DataSources::Espn::Client.define_singleton_method(:new, original_constructor)
    end

    assert_redirected_to admin_league_path(league)
    league.reload
    assert_equal 0.5, league.ppr
    assert_equal 3, league.wr_slots
    assert_equal 2, league.flex_slots
    assert_equal 17, league.roster_size
    assert_equal "ESPN Test League", league.espn_settings["name"]
    assert league.espn_synced_at.present?
    assert_equal 7, teams(:one).reload.espn_team_id
    assert_equal original_order, teams(:one).draft_order
    assert_equal 2, league.teams.find_by!(espn_team_id: 8).draft_order
    assert_equal "Josh Allen", league.espn_seasons.find_by!(season: 2026).draft_picks.first.player_name
    assert_equal 321.45, league.league_player_scores.find_by!(season: 2025).points
  end

  test "ESPN client returns a typed league snapshot" do
    requested_uri = nil
    response = Struct.new(:code, :body).new("200", SETTINGS_PAYLOAD.to_json)
    client = DataSources::Espn::Client.new(fetcher: ->(uri) { requested_uri = uri; response })

    snapshot = client.fetch_league_snapshot(year: 2026, league_id: 123_456)

    assert_instance_of DataSources::Espn::LeagueSnapshot, snapshot
    assert_equal 2026, snapshot.season
    assert_equal [ "RED", "NEW" ], snapshot.teams.map(&:abbreviation)
    assert_equal [ "owner-1" ], snapshot.teams.first.owner_ids
    assert_equal 1, snapshot.teams.first.final_rank
    assert_equal %w[mTeam mSettings mDraftDetail mStandings], URI.decode_www_form(requested_uri.query).map(&:last)
  end

  test "ESPN client uses and unwraps the legacy history endpoint before 2018" do
    requested_uri = nil
    payload = SETTINGS_PAYLOAD.deep_dup
    payload["seasonId"] = 2017
    response = Struct.new(:code, :body).new("200", [ payload ].to_json)
    client = DataSources::Espn::Client.new(fetcher: ->(uri) { requested_uri = uri; response })

    snapshot = client.fetch_league_snapshot(year: 2017, league_id: 123_456)

    assert_equal 2017, snapshot.season
    assert_equal "/apis/v3/games/ffl/leagueHistory/123456", requested_uri.path
    assert_equal "2017", URI.decode_www_form(requested_uri.query).to_h.fetch("seasonId")
    assert_equal %w[mTeam mSettings mDraftDetail mStandings], URI.decode_www_form(requested_uri.query).filter_map { |key, value| value if key == "view" }
  end

  test "league snapshot ignores ESPN's undrafted placeholder picks" do
    payload = SETTINGS_PAYLOAD.deep_dup
    payload["draftDetail"]["picks"] << {
      "teamId" => 7, "playerId" => -1, "roundId" => 1, "roundPickNumber" => 2
    }
    snapshot = DataSources::Espn::LeagueSnapshot.from_payload(payload)
    catalog = DataSources::Espn::PlayerCatalog.new([])

    assert_equal 1, snapshot.draft_picks(player_catalog: catalog).size
  end
end
