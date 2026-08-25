require "test_helper"

class Admin::EspnConnectionsControllerTest < ActionDispatch::IntegrationTest
  SETTINGS_PAYLOAD = {
    "seasonId" => 2026,
    "status" => { "previousSeasons" => [] },
    "members" => [],
    "teams" => [ { "id" => 7, "abbrev" => "RED", "name" => "Red Hawks", "owners" => [] } ],
    "draftDetail" => { "drafted" => false, "picks" => [] },
    "settings" => {
      "name" => "Private ESPN League",
      "size" => 12,
      "draftSettings" => { "type" => 1 },
      "rosterSettings" => {
        "lineupSlotCounts" => {
          "0" => 1, "2" => 2, "4" => 3, "6" => 1, "16" => 1,
          "17" => 1, "20" => 6, "23" => 2
        }
      },
      "scoringSettings" => {
        "scoringItems" => [ { "statId" => 53, "points" => 0.5 } ]
      }
    }
  }.freeze

  setup do
    @league = leagues(:one)
    @league.update!(espn_league_id: "123456")
  end

  test "commissioner can open the private league connection form" do
    sign_in_as users(:commissioner)

    get new_admin_league_espn_connection_path(@league)

    assert_response :success
    assert_select "input[name=espn_s2]"
    assert_select "input[name=swid]"
    assert_select "input[type=submit][value='Connect and sync league']"
  end

  test "connecting verifies credentials and imports rules" do
    sign_in_as users(:commissioner)
    client = fake_client

    with_espn_client(client) do
      post admin_league_espn_connection_path(@league), params: {
        espn_s2: "private-cookie",
        swid: "{PRIVATE-SWID}"
      }
    end

    assert_redirected_to admin_league_path(@league)
    @league.reload
    assert_equal 0.5, @league.ppr
    assert_equal 3, @league.wr_slots
    assert_equal "Private ESPN League", @league.espn_settings["name"]

    follow_redirect!
    assert_select "form[action='#{admin_league_espn_connection_path(@league)}']", text: /Disconnect ESPN/
  end

  test "invalid credentials are not stored or imported" do
    sign_in_as users(:commissioner)
    client = Object.new
    client.define_singleton_method(:fetch_league_snapshot) do |**|
      raise DataSources::HttpError, "ESPN denied access."
    end

    with_espn_client(client) do
      post admin_league_espn_connection_path(@league), params: {
        espn_s2: "bad-cookie",
        swid: "{BAD-SWID}"
      }
    end

    assert_response :unprocessable_entity
    assert_select "div", text: /ESPN denied access/
    assert_nil @league.reload.espn_synced_at
  end

  test "commissioner can disconnect ESPN credentials" do
    sign_in_as users(:commissioner)
    with_espn_client(fake_client) do
      post admin_league_espn_connection_path(@league), params: {
        espn_s2: "private-cookie",
        swid: "{PRIVATE-SWID}"
      }
    end

    delete admin_league_espn_connection_path(@league)

    assert_redirected_to admin_league_path(@league)
    follow_redirect!
    assert_select "a[href='#{new_admin_league_espn_connection_path(@league)}']", text: /Connect private league/
  end

  test "regular members cannot connect ESPN credentials" do
    sign_in_as users(:member)

    get new_admin_league_espn_connection_path(@league)

    assert_redirected_to root_path
  end

  private

  def fake_client
    snapshot = DataSources::Espn::LeagueSnapshot.from_payload(SETTINGS_PAYLOAD)
    Object.new.tap do |client|
      client.define_singleton_method(:fetch_league_snapshot) { |**| snapshot }
      client.define_singleton_method(:fetch_players) { |**| [] }
      client.define_singleton_method(:fetch_player_updates) { |**| [] }
      client.define_singleton_method(:fetch_player_scores) do |**|
        [ DataSources::Espn::Client::PlayerScore.new(espn_id: 1, points: BigDecimal("333.3"), stats: {}) ]
      end
    end
  end

  def with_espn_client(client)
    original_constructor = DataSources::Espn::Client.method(:new)
    DataSources::Espn::Client.define_singleton_method(:new) { |**| client }
    yield
  ensure
    DataSources::Espn::Client.define_singleton_method(:new, original_constructor)
  end
end
