require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "formats elapsed pick time and applies shame thresholds" do
    assert_equal "0:59", format_pick_duration(59)
    assert_equal "1:00", format_pick_duration(60)
    assert_equal "1:01:05", format_pick_duration(3665)

    assert_equal "text-slate-400", pick_duration_classes(59)
    assert_equal "text-yellow-300", pick_duration_classes(60)
    assert_equal "text-yellow-300", pick_duration_classes(89)
    assert_equal "text-red-400", pick_duration_classes(90)
  end

  test "provides full-surface colors for every draft position" do
    expected_backgrounds = {
      "QB" => "bg-amber-400/20",
      "RB" => "bg-emerald-400/20",
      "WR" => "bg-blue-400/20",
      "TE" => "bg-violet-400/20",
      "K" => "bg-pink-400/20",
      "DST" => "bg-cyan-400/20"
    }

    expected_backgrounds.each do |position, background|
      assert_includes position_surface_classes(position), background
    end
    assert_includes position_surface_classes("UNKNOWN"), "bg-white/10"
  end

  test "requests NFL logos at display size through the ESPN CDN" do
    assert_equal "https://a.espncdn.com/combiner/i?img=/i/teamlogos/nfl/500/atl.png&w=80&h=80", nfl_team_logo_url("ATL")
    assert_equal "https://a.espncdn.com/combiner/i?img=/i/teamlogos/nfl/500/wsh.png&w=80&h=80", nfl_team_logo_url("WAS")
  end

  test "gives every placement of a portrait the same URL" do
    player = players(:one)
    player.headshot.attach(io: StringIO.new("headshot"), filename: "headshot.png", content_type: "image/png")

    desktop = player_portrait_attributes(player, classes: "h-full w-full")
    board = player_portrait_attributes(player, classes: "size-8")

    assert_equal desktop[:src], board[:src]
    assert_match %r{/rails/active_storage/representations/proxy/}, desktop[:src]
  end

  test "marks portraits and logos as deferrable decorative images" do
    logo = nfl_team_logo_attributes("ATL", classes: "size-7")

    assert_equal "", logo[:alt]
    assert_equal "lazy", logo[:loading]
    assert_equal "async", logo[:decoding]
    assert_equal "low", logo[:fetchpriority]
    assert_equal "size-7", logo[:class]
  end

  test "links a generated portrait straight at the CDN" do
    player = players(:one)
    attach_real_headshot(player)
    key = player.headshot.variant(:portrait).processed.key

    with_cdn_host("cdn.example.com") do
      assert_equal "https://cdn.example.com/#{key}", player_portrait_url(player)
    end
  end

  test "falls back to the proxy for a portrait the CDN cannot have yet" do
    player = players(:one)
    player.headshot.attach(io: StringIO.new("headshot"), filename: "headshot.png", content_type: "image/png")

    with_cdn_host("cdn.example.com") do
      assert_match %r{/rails/active_storage/representations/proxy/}, player_portrait_url(player)
    end
  end

  test "serves portraits through the proxy when no CDN is configured" do
    player = players(:one)
    attach_real_headshot(player)
    player.headshot.variant(:portrait).processed

    with_cdn_host(nil) do
      assert_match %r{/rails/active_storage/representations/proxy/}, player_portrait_url(player)
    end
  end

  test "keeps a defense portrait pointed at its team logo" do
    defense = players(:two)
    defense.update!(position: "DST", pro_team: "BUF")

    attributes = player_portrait_attributes(defense, classes: "h-full w-full")

    assert_equal nfl_team_logo_url("BUF"), attributes[:src]
    assert_equal "BUF", attributes[:title]
    assert_includes attributes[:class], "object-contain"
  end

  private

  def attach_real_headshot(player)
    player.headshot.attach(
      io: file_fixture("headshot.png").open, filename: "headshot.png", content_type: "image/png"
    )
  end

  def with_cdn_host(host)
    previous = Rails.configuration.x.cdn_host
    Rails.configuration.x.cdn_host = host
    yield
  ensure
    Rails.configuration.x.cdn_host = previous
  end
end
