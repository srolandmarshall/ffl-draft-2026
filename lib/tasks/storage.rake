namespace :storage do
  desc "Report reclaimable space in the storage bucket"
  task report: :environment do
    $stdout.sync = true

    orphans = OrphanedStorageObjects.new
    orphan_count = orphans.count
    puts format("Orphaned files (no blob row, settled): %d, %.1f MB", orphan_count, orphans.total_bytes / 1048576.0)

    superseded = superseded_variant_records
    puts format("Superseded portrait variants: %d, %.1f MB", superseded.count, superseded_variant_bytes / 1048576.0)

    puts "Reclaim with: bin/rails storage:purge_orphans CONFIRM=yes / storage:purge_superseded_variants CONFIRM=yes"
  rescue OrphanedStorageObjects::UnsupportedService => error
    warn "Cannot scan for orphans: #{error.message}"
  end

  desc "Delete storage files that no blob refers to (CONFIRM=yes required)"
  task purge_orphans: :environment do
    $stdout.sync = true
    orphans = OrphanedStorageObjects.new

    # Deleting an original is not recoverable from inside the app; it would need re-syncing from
    # nflverse. Make the caller say so out loud.
    unless ENV["CONFIRM"] == "yes"
      puts format("Would delete %d file(s), %.1f MB. Re-run with CONFIRM=yes.", orphans.count, orphans.total_bytes / 1048576.0)
      next
    end

    deleted = orphans.delete_all
    puts "Deleted #{deleted} orphaned file#{'s' unless deleted == 1}."
    puts "The bucket is versioned, so these are now delete markers over retained versions."
    puts "Space is reclaimed once a lifecycle rule expires noncurrent versions."
  end

  desc "Purge portrait variants superseded by the current size and format (CONFIRM=yes required)"
  task purge_superseded_variants: :environment do
    $stdout.sync = true
    records = superseded_variant_records

    unless ENV["CONFIRM"] == "yes"
      puts format("Would purge %d variant record(s), %.1f MB. Re-run with CONFIRM=yes.", records.count, superseded_variant_bytes / 1048576.0)
      next
    end

    purged = 0
    records.each do |record|
      record.image.purge
      record.destroy
      purged += 1
    rescue StandardError => error
      warn "Unable to purge variant record #{record.id}: #{error.class}: #{error.message}"
    end

    puts "Purged #{purged} superseded variant record#{'s' unless purged == 1}."
  end
end

# Variants are derived data, so dropping the wrong ones costs a regeneration rather than the
# image itself. The current digest is read from the live variant definition so that changing the
# portrait size or format does not leave this task deleting the wrong generation.
def current_portrait_digest
  player = Player.joins(:headshot_attachment).first
  player&.headshot&.variant(:portrait)&.variation&.digest
end

def superseded_variant_records
  digest = current_portrait_digest
  return ActiveStorage::VariantRecord.none unless digest

  ActiveStorage::VariantRecord.where.not(variation_digest: digest)
end

def superseded_variant_bytes
  ActiveStorage::Blob
    .joins(:attachments)
    .where(active_storage_attachments: { record_type: "ActiveStorage::VariantRecord", record_id: superseded_variant_records.select(:id) })
    .sum(:byte_size)
end
