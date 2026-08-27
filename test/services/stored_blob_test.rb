# frozen_string_literal: true

require "test_helper"

class StoredBlobTest < ActiveSupport::TestCase
  test "reports an intact blob" do
    player = players(:one)
    player.headshot.attach(io: StringIO.new("headshot"), filename: "headshot.png", content_type: "image/png")

    stored = StoredBlob.for(player.headshot.blob)

    assert_predicate stored, :intact?
    refute_predicate stored, :missing?
    refute_predicate stored, :truncated?
    assert_nil stored.problem
  end

  test "reports a blob whose file is gone" do
    player = players(:one)
    player.headshot.attach(io: StringIO.new("headshot"), filename: "headshot.png", content_type: "image/png")
    blob = player.headshot.blob
    blob.service.delete(blob.key)

    stored = StoredBlob.for(blob)

    assert_predicate stored, :missing?
    refute_predicate stored, :intact?
    assert_equal "missing from storage", stored.problem
  end

  test "reports a blob that was stored short of its recorded size" do
    player = players(:one)
    player.headshot.attach(io: StringIO.new("headshot"), filename: "headshot.png", content_type: "image/png")
    blob = player.headshot.blob
    blob.update_column(:byte_size, blob.byte_size + 500)

    stored = StoredBlob.for(blob)

    assert_predicate stored, :truncated?
    refute_predicate stored, :intact?
    assert_match(/8 bytes stored, 508 expected/, stored.problem)
  end
end
