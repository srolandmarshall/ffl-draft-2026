class Player < ApplicationRecord
  POSITIONS = %w[QB RB WR TE K DST].freeze

  has_one_attached :headshot
  has_many :picks, dependent: :restrict_with_error
  has_many :league_player_scores, dependent: :destroy

  def league_fantasy_points(league:, season:)
    league_score(league:, season:)&.points
  end

  def league_score(league:, season:)
    league_player_scores.find { |score| score.league_id == league.id && score.season == season }
  end

  normalizes :position, :pro_team, with: ->(value) { value.strip.upcase }

  validates :name, :position, :pro_team, presence: true
  validates :position, inclusion: { in: POSITIONS }
  validates :espn_id, uniqueness: true, allow_nil: true
  validates :ffc_id, uniqueness: true, allow_nil: true
  validates :name, uniqueness: { scope: [ :pro_team, :position ] }

  scope :active, -> { where(active: true) }
  scope :alphabetical, -> { order(:name) }
  scope :by_ranking, -> { order(Arel.sql("ranking IS NULL, ranking ASC"), :name) }

  validates :ranking, numericality: { greater_than: 0 }, allow_nil: true
  validates :position_rank, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  def injured?
    injury_status.present? && !injury_status.in?(%w[ACTIVE NORMAL])
  end

  def injury_status_label
    {
      "INJURY_RESERVE" => "IR",
      "PHYSICALLY_UNABLE_TO_PERFORM" => "PUP",
      "NON_FOOTBALL_INJURY" => "NFI",
      "SUSPENSION" => "Suspended"
    }.fetch(injury_status, injury_status.to_s.titleize)
  end

  def injury_status_abbreviation
    {
      "QUESTIONABLE" => "Q",
      "DOUBTFUL" => "D",
      "OUT" => "O",
      "INJURY_RESERVE" => "IR",
      "PHYSICALLY_UNABLE_TO_PERFORM" => "PUP",
      "NON_FOOTBALL_INJURY" => "NFI",
      "SUSPENSION" => "SSPD",
      "INJURED" => "INJ"
    }.fetch(injury_status, injury_status.to_s.first(4).upcase)
  end

  def actual_stats?
    stats_season.present? && actual_stats.present?
  end

  def actual_stat_line
    return unless actual_stats?

    case position
    when "QB"
      "#{stat(:completions)}/#{stat(:attempts)} · #{delimited_stat(:passing_yards)} pass yd · #{stat(:passing_tds)} TD · #{stat(:passing_interceptions)} INT · #{delimited_stat(:rushing_yards)} rush yd"
    when "RB"
      "#{stat(:carries)} car · #{delimited_stat(:rushing_yards)} rush yd · #{stat(:receptions)}/#{stat(:targets)} rec · #{delimited_stat(:receiving_yards)} rec yd · #{total_touchdowns} TD"
    when "WR", "TE"
      "#{stat(:receptions)}/#{stat(:targets)} rec · #{delimited_stat(:receiving_yards)} rec yd · #{stat(:receiving_tds)} TD"
    when "K"
      "#{stat(:fg_made)}/#{stat(:fg_att)} FG · #{stat(:pat_made)}/#{stat(:pat_att)} XP"
    end
  end

  def actual_fantasy_points(ppr:)
    return unless actual_stats?

    actual_stats["fantasy_points"].to_f + (stat(:receptions).to_f * ppr.to_f)
  end

  def actual_games
    stat(:games) if actual_stats?
  end

  def draft_games
    position == "DST" ? 17 : actual_games
  end

  def passing_stat_line
    return unless actual_stats? && stat(:attempts).positive?

    "#{stat(:completions)}/#{stat(:attempts)} · #{delimited_stat(:passing_yards)} yd · #{stat(:passing_tds)} TD · #{stat(:passing_interceptions)} INT"
  end

  def rushing_stat_line
    return unless actual_stats? && stat(:carries).positive?

    "#{stat(:carries)} att · #{delimited_stat(:rushing_yards)} yd · #{stat(:rushing_tds)} TD"
  end

  def receiving_stat_line
    return unless actual_stats? && (stat(:targets).positive? || stat(:receptions).positive?)

    "#{stat(:receptions)}/#{stat(:targets)} · #{delimited_stat(:receiving_yards)} yd · #{stat(:receiving_tds)} TD"
  end

  def kicking_stat_line
    return unless actual_stats? && (stat(:fg_att).positive? || stat(:pat_att).positive?)

    "#{stat(:fg_made)}/#{stat(:fg_att)} FG · #{stat(:pat_made)}/#{stat(:pat_att)} XP"
  end

  def draft_stat_lines
    return [] unless actual_stats?

    case position
    when "QB"
      [ [ "Pass", passing_stat_line ], [ "Rush", meaningful_rushing? ? rushing_stat_line : nil ] ]
    when "RB"
      [ [ "Rush", rushing_stat_line ], [ "Rec", receiving_stat_line ] ]
    when "WR"
      [ [ "Rec", receiving_stat_line ], [ "Rush", receiver_rushing? ? rushing_stat_line : nil ] ]
    when "TE"
      [ [ "Rec", receiving_stat_line ], [ "Rush", receiver_rushing? ? rushing_stat_line : nil ] ]
    when "K"
      [ [ "Kick", kicking_stat_line ] ]
    else
      []
    end.filter_map { |label, value| [ label, value ] if value }
  end

  def draft_stat_groups
    return [] unless actual_stats?

    case position
    when "QB"
      [ stat_group("Passing", passing_draft_stats), stat_group("Rushing", rushing_draft_stats, show: meaningful_rushing?) ]
    when "RB"
      [ stat_group("Rushing", rushing_draft_stats), stat_group("Receiving", receiving_draft_stats) ]
    when "WR"
      [ stat_group("Receiving", receiving_draft_stats), stat_group("Rushing", rushing_draft_stats, show: receiver_rushing?) ]
    when "TE"
      [ stat_group("Receiving", receiving_draft_stats), stat_group("Rushing", rushing_draft_stats, show: receiver_rushing?) ]
    when "K"
      [ stat_group("Kicking", kicking_draft_stats) ]
    else
      []
    end.compact
  end

  def draft_touchdown_stats
    return [] unless actual_stats?

    stats = case position
    when "QB"
      [ [ "PASS", stat(:passing_tds) ], [ "RUSH", stat(:rushing_tds) ], [ "REC", stat(:receiving_tds) ] ]
    when "RB"
      [ [ "RUSH", stat(:rushing_tds) ], [ "REC", stat(:receiving_tds) ] ]
    when "WR", "TE"
      [ [ "REC", stat(:receiving_tds) ], [ "RUSH", stat(:rushing_tds) ] ]
    else
      []
    end

    stats.select { |_label, value| value.positive? }
  end

  private

  def stat_group(label, stats, show: true)
    { label:, stats: } if show && stats.any?
  end

  def passing_draft_stats
    return [] unless stat(:attempts).positive?

    [ [ "CMP", stat(:completions) ], [ "ATT", stat(:attempts) ], [ "YDS", delimited_stat(:passing_yards) ],
     [ "TD", stat(:passing_tds) ], [ "INT", stat(:passing_interceptions) ] ]
  end

  def rushing_draft_stats
    return [] unless stat(:carries).positive?

    [ [ "ATT", stat(:carries) ], [ "YDS", delimited_stat(:rushing_yards) ], [ "YPG", yards_per_game(:rushing_yards) ] ]
  end

  def receiving_draft_stats
    return [] unless stat(:targets).positive? || stat(:receptions).positive?

    [ [ "REC", stat(:receptions) ], [ "TGT", stat(:targets) ], [ "YDS", delimited_stat(:receiving_yards) ],
     [ "YPG", yards_per_game(:receiving_yards) ] ]
  end

  def kicking_draft_stats
    return [] unless stat(:fg_att).positive? || stat(:pat_att).positive?

    [ [ "FGM", stat(:fg_made) ], [ "FGA", stat(:fg_att) ], [ "XPM", stat(:pat_made) ], [ "XPA", stat(:pat_att) ] ]
  end

  def yards_per_game(stat_name)
    return "—" unless actual_games.to_i.positive?

    format("%.1f", stat(stat_name).fdiv(actual_games))
  end

  def stat(name)
    actual_stats[name.to_s].to_i
  end

  def delimited_stat(name)
    stat(name).to_fs(:delimited)
  end

  def total_touchdowns
    stat(:rushing_tds) + stat(:receiving_tds)
  end

  def meaningful_rushing?
    stat(:rushing_yards) >= 50 || stat(:rushing_tds).positive?
  end

  def receiver_rushing?
    stat(:rushing_yards) >= 50 || stat(:rushing_tds).positive?
  end
end
