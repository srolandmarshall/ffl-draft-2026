# frozen_string_literal: true

require "test_helper"

class OrphanedStorageObjectsTest < ActiveSupport::TestCase
  StoredObject = Struct.new(:key, :size, :last_modified)

  test "finds files with no blob row" do
    player = players(:one)
    player.headshot.attach(io: StringIO.new("headshot"), filename: "headshot.png", content_type: "image/png")
    known = player.headshot.blob.key

    orphans = OrphanedStorageObjects.new(service: service_holding(
      StoredObject.new(known, 8, 1.week.ago),
      StoredObject.new("abandoned-one", 500, 1.week.ago),
      StoredObject.new("abandoned-two", 250, 1.week.ago)
    ))

    assert_equal %w[abandoned-one abandoned-two], orphans.map(&:key).sort
    assert_equal 750, orphans.total_bytes
  end

  test "ignores a file written too recently to be sure about" do
    # Active Storage writes the file before committing the blob row, so a key missing from the
    # database right now can be an upload in flight rather than an orphan.
    orphans = OrphanedStorageObjects.new(service: service_holding(
      StoredObject.new("just-uploaded", 500, 2.minutes.ago),
      StoredObject.new("long-abandoned", 500, 1.week.ago)
    ))

    assert_equal [ "long-abandoned" ], orphans.map(&:key)
  end

  test "deletes only what it reports" do
    service = service_holding(
      StoredObject.new("just-uploaded", 500, 2.minutes.ago),
      StoredObject.new("long-abandoned", 500, 1.week.ago)
    )

    assert_equal 1, OrphanedStorageObjects.new(service: service).delete_all
    assert_equal [ "long-abandoned" ], service.deleted
  end

  test "refuses to guess on a service it cannot enumerate" do
    orphans = OrphanedStorageObjects.new(service: Object.new)

    assert_raises(OrphanedStorageObjects::UnsupportedService) { orphans.count }
  end

  private

  def service_holding(*objects)
    bucket = Struct.new(:objects).new(objects)
    Class.new do
      attr_reader :bucket, :deleted

      def initialize(bucket)
        @bucket = bucket
        @deleted = []
      end

      def delete(key) = @deleted << key
    end.new(bucket)
  end
end
