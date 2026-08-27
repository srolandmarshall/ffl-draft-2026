def damaged_headshots
  Player.with_attached_headshot.filter_map do |player|
    next unless player.headshot.attached?

    problem = StoredBlob.for(player.headshot.blob).problem
    [ player, problem ] if problem
  end
end

namespace :headshots do
  desc "Queue portrait generation for headshots that have no variant yet"
  task enqueue_portraits: :environment do
    # Generating inline over an SSH session lost the run three times: twice to a deploy
    # restarting the machine, once to the connection dropping on its own. Solid Queue keeps its
    # jobs in the database, so enqueuing survives both, and the worker's threads overlap the S3
    # download and upload that dominate each transform.
    $stdout.sync = true
    queued = 0
    present = 0

    Player.with_attached_headshot.find_each do |player|
      next unless player.headshot.attached?

      variant = player.headshot.variant(:portrait)
      if variant.key.present?
        present += 1
      else
        ActiveStorage::TransformJob.perform_later(player.headshot.blob, variant.variation.transformations)
        queued += 1
      end
    end

    puts "Queued #{queued} portrait#{'s' unless queued == 1}, #{present} already present."
    puts "Watch with: bin/rails headshots:portrait_status"
  end

  desc "Report how many headshots still need a portrait variant"
  task portrait_status: :environment do
    total = 0
    present = 0

    Player.with_attached_headshot.find_each do |player|
      next unless player.headshot.attached?

      total += 1
      present += 1 if player.headshot.variant(:portrait).key.present?
    end

    # Development does not run Solid Queue, so its tables are absent there.
    pending = begin
      SolidQueue::Job.where(class_name: "ActiveStorage::TransformJob", finished_at: nil).count
    rescue ActiveRecord::StatementInvalid, NameError
      nil
    end

    puts "#{present}/#{total} portraits generated, #{total - present} remaining."
    puts "#{pending} transform job(s) unfinished." if pending
  end

  desc "Report headshots whose stored file is missing or truncated"
  task verify: :environment do
    $stdout.sync = true
    broken = damaged_headshots

    if broken.empty?
      puts "All headshots match their recorded size."
    else
      broken.each { |player, problem| puts "#{player.id}\t#{player.name}\t#{problem}" }
      puts "#{broken.size} damaged headshot#{'s' unless broken.size == 1}. Repair with: bin/rails headshots:repair"
    end
  end

  desc "Re-download headshots whose stored file is missing or truncated"
  task repair: :environment do
    # The sync only re-fetches when the attachment is absent or its URL changed, so a corrupt but
    # attached headshot is never retried. Purging first is what lets it be replaced.
    $stdout.sync = true
    client = DataSources::Nflverse::Client.new
    repaired = 0
    failed = 0

    damaged_headshots.each do |player, problem|
      puts "#{player.name}: #{problem}"

      if player.headshot_url.blank?
        warn "  no headshot_url to re-download from, purging only"
        player.headshot.purge
        failed += 1
        next
      end

      begin
        download = client.fetch_headshot(url: player.headshot_url)
        player.headshot.purge
        player.headshot.attach(
          io: download.io,
          filename: "player-#{player.id}.#{download.extension}",
          content_type: download.content_type
        )
        repaired += 1
        puts "  re-downloaded"
      rescue StandardError => error
        failed += 1
        warn "  failed: #{error.class}: #{error.message}"
      end
    end

    puts "Repaired #{repaired}, failed #{failed}."
  end

  desc "Generate portrait variants inline (prefer enqueue_portraits; this dies with the session)"
  task backfill_portraits: :environment do
    $stdout.sync = true
    players = Player.with_attached_headshot.select { |player| player.headshot.attached? }
    total = players.size
    generated = 0
    skipped = 0
    failed = 0

    puts "Backfilling portraits for #{total} player#{'s' unless total == 1}."

    players.each_with_index do |player, index|
      variant = player.headshot.variant(:portrait)
      if variant.key.present?
        skipped += 1
      else
        variant.processed
        generated += 1
      end
    rescue StandardError => error
      failed += 1
      warn "Unable to generate portrait for player #{player.id}: #{error.class}: #{error.message}"
    ensure
      position = index + 1
      puts "#{position}/#{total} — #{generated} generated, #{skipped} already present, #{failed} failed" if (position % 25).zero? || position == total
    end

    puts "Done. #{generated} generated, #{skipped} already present, #{failed} failed."
  end
end
