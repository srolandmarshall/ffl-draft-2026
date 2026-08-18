# frozen_string_literal: true

require "test_helper"

class Components::FormErrorsTest < ActiveSupport::TestCase
  test "renders validation errors" do
    record = User.new
    record.errors.add(:email, "is already assigned")

    html = Components::FormErrors.new(record).call

    assert_includes html, "1 error prevented this from being saved"
    assert_includes html, "Email is already assigned"
  end

  test "renders no markup for a valid record" do
    assert_empty Components::FormErrors.new(User.new).call
  end
end
