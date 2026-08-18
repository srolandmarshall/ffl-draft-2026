# frozen_string_literal: true

require "test_helper"

class Components::FlashTest < ActiveSupport::TestCase
  test "renders flash messages with accessible status semantics" do
    html = Components::Flash.new(notice: "Draft saved", alert: "Pick is invalid").call

    assert_includes html, 'role="status"'
    assert_includes html, 'role="alert"'
    assert_includes html, "Draft saved"
    assert_includes html, "Pick is invalid"
    assert_includes html, "border-red-400/40"
  end

  test "renders no markup when there are no messages" do
    assert_empty Components::Flash.new({}).call
  end
end
