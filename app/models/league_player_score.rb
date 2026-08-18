class LeaguePlayerScore < ApplicationRecord
  DST_STATS = {
    "SACK" => "99", "INT" => "95", "FR" => "96", "BLK" => "97", "SFTY" => "98"
  }.freeze
  DST_TOUCHDOWNS = { "DEF" => "94", "KR" => "101", "PR" => "102" }.freeze

  belongs_to :league
  belongs_to :player

  validates :season, numericality: { only_integer: true, greater_than: 2000 }
  validates :points, numericality: true
  validates :player_id, uniqueness: { scope: [ :league_id, :season ] }

  def self.replace_for!(league:, season:, scores:)
    players_by_espn_id = Player.where(espn_id: scores.map(&:espn_id)).index_by(&:espn_id)
    created = 0

    transaction do
      where(league:, season:).delete_all
      scores.each do |score|
        player = players_by_espn_id[score.espn_id]
        next unless player

        create!(league:, player:, season:, points: score.points, stats: score.stats)
        created += 1
      end
    end

    created
  end

  def dst_stat_groups
    return [] unless player.position == "DST"

    production = DST_STATS.filter_map do |label, stat_id|
      value = stats.fetch(stat_id, 0).to_i
      [ label, value ] if value.positive?
    end
    production.any? ? [ { label: "Defense", stats: production } ] : []
  end

  def dst_touchdown_stats
    return [] unless player.position == "DST"

    DST_TOUCHDOWNS.filter_map do |label, stat_id|
      value = stats.fetch(stat_id, 0).to_i
      [ label, value ] if value.positive?
    end
  end
end
