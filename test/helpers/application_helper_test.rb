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
end
