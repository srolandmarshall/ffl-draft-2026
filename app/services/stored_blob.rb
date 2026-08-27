# frozen_string_literal: true

# What storage actually holds for a blob, as opposed to what the database records.
#
# The two drift apart when a download is cut short: Net::HTTP hands back a truncated body without
# error, Active Storage attaches it, and the blob's recorded byte_size no longer matches its
# contents. Nothing notices until something tries to read the file and fails a checksum, which for
# a portrait meant a transform job retrying forever.
class StoredBlob
  def self.for(blob) = new(blob)

  def initialize(blob)
    @blob = blob
  end

  def missing? = byte_size.nil?

  def truncated? = byte_size.present? && byte_size != @blob.byte_size

  def intact? = !missing? && !truncated?

  def problem
    return "missing from storage" if missing?
    return "#{byte_size} bytes stored, #{@blob.byte_size} expected" if truncated?

    nil
  end

  # nil when the object is not there at all.
  def byte_size
    return @byte_size if defined?(@byte_size)

    @byte_size = resolve_byte_size
  end

  private

  def resolve_byte_size
    service = @blob.service
    return nil unless service.exist?(@blob.key)

    if service.respond_to?(:bucket)
      service.bucket.object(@blob.key).content_length
    elsif service.respond_to?(:path_for)
      File.size(service.path_for(@blob.key))
    end
  rescue StandardError
    nil
  end
end
