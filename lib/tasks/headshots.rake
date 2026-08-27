namespace :headshots do
  desc "Generate the portrait variant for headshots attached before preprocessing was enabled"
  task backfill_portraits: :environment do
    # A deploy restarts the machine and kills this task partway through, so report progress as
    # it goes rather than only at the end. Re-running is cheap: an already generated variant
    # is a lookup, not a transform.
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
