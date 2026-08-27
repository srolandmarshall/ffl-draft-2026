namespace :headshots do
  desc "Generate the portrait variant for headshots attached before preprocessing was enabled"
  task backfill_portraits: :environment do
    players = Player.with_attached_headshot.select { |player| player.headshot.attached? }
    generated = 0
    failed = 0

    players.each do |player|
      player.headshot.variant(:portrait).processed
      generated += 1
    rescue StandardError => error
      failed += 1
      warn "Unable to generate portrait for player #{player.id}: #{error.class}: #{error.message}"
    end

    puts "Generated #{generated} portrait#{'s' unless generated == 1}, #{failed} failed."
  end
end
