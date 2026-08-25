# frozen_string_literal: true

require "test_helper"

class Components::FlashRegionTest < ActiveSupport::TestCase
  test "provides a stable Turbo replacement target" do
    html = Components::FlashRegion.new(messages: { notice: "Saved" }).call

    assert_includes html, 'id="flash"'
    assert_includes html, "Saved"
  end
end
