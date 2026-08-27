# frozen_string_literal: true

# Files in the storage bucket that no Active Storage blob refers to.
#
# They accumulate when a blob row is deleted but its file is not: a purge whose delete failed, or
# a background purge job that died before running. Nothing in the app can reach them again, so
# they are pure cost.
class OrphanedStorageObjects
  include Enumerable

  # An object is only orphaned if its blob row is absent for good. Active Storage writes the file
  # before committing the row, so a key that is missing from the database right now may just be an
  # upload in flight. Ignoring anything recent keeps this from deleting a live attachment.
  SETTLING_PERIOD = 1.day

  UnsupportedService = Class.new(StandardError)

  def initialize(service: ActiveStorage::Blob.service, settling_period: SETTLING_PERIOD, now: Time.current)
    @service = service
    @settling_period = settling_period
    @now = now
  end

  def each
    return enum_for(:each) unless block_given?

    known_keys = ActiveStorage::Blob.pluck(:key).to_set
    cutoff = @now - @settling_period

    objects.each do |object|
      next if known_keys.include?(object.key)
      next if object.last_modified > cutoff

      yield object
    end
  end

  def total_bytes = sum(&:size)

  def delete_all
    count = 0
    each do |object|
      @service.delete(object.key)
      count += 1
    end
    count
  end

  private

  def objects
    raise UnsupportedService, "#{@service.class} cannot enumerate its objects" unless @service.respond_to?(:bucket)

    @service.bucket.objects
  end
end
