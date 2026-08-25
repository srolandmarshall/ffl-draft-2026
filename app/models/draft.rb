class Draft < ApplicationRecord
  belongs_to :league

  has_many :draft_entries, -> { order(:position) }, dependent: :destroy
  has_many :teams, through: :draft_entries
  has_many :picks, -> { order(:overall_number) }, dependent: :destroy

  enum :status, { setup: 0, live: 1, complete: 2 }
  enum :draft_type, { snake: 0, linear: 1 }

  ROSTER_SLOT_ATTRIBUTES = %i[qb_slots rb_slots wr_slots te_slots flex_slots k_slots dst_slots bench_slots].freeze

  before_validation :assign_public_id, on: :create
  after_commit :enqueue_scheduled_start, if: :scheduled_start_changed?

  validates :name, :public_id, presence: true
  validates :public_id, uniqueness: true
  validates :rounds, numericality: { only_integer: true, in: 1..30 }
  validates :team_count, numericality: { only_integer: true, in: 2..20 }
  validates(*ROSTER_SLOT_ATTRIBUTES, numericality: { only_integer: true, in: 0..20 })
  validates :ppr, inclusion: { in: [ 0, 0.5, 1 ], message: "must be 0, 0.5, or 1" }
  validates :scheduled_start_at, comparison: { greater_than: -> { Time.current } }, allow_nil: true, if: :will_save_change_to_scheduled_start_at?
  before_validation :set_rounds_from_roster, if: :setup?

  def total_picks
    rounds * draft_entries.size
  end

  def next_overall_number
    picks.size + 1
  end

  def current_round
    return 1 if draft_entries.empty?

    ((next_overall_number - 1) / draft_entries.size) + 1
  end

  def current_team
    return if complete?

    team_for_overall_number(next_overall_number)
  end

  def team_for_overall_number(overall_number)
    entries = draft_entries.to_a
    return if entries.empty? || overall_number.to_i < 1 || overall_number.to_i > rounds * entries.size

    round = ((overall_number - 1) / entries.size) + 1
    offset = (overall_number - 1) % entries.size
    entry_index = snake? && round.even? ? entries.size - offset - 1 : offset
    entries[entry_index].team
  end

  def picks_until_team(team)
    return unless team

    (next_overall_number..total_picks).each_with_index do |overall_number, picks_away|
      return picks_away if team_for_overall_number(overall_number) == team
    end

    nil
  end

  def roster_size
    ROSTER_SLOT_ATTRIBUTES.sum { |attribute| public_send(attribute) }
  end

  def roster_summary
    ROSTER_SLOT_ATTRIBUTES.filter_map do |attribute|
      count = public_send(attribute)
      "#{attribute.to_s.delete_suffix('_slots').upcase} #{count}" if count.positive?
    end.join(" · ")
  end

  def available_players
    Player.active.where.not(id: picks.select(:player_id))
  end

  def prior_season_fantasy_points_for(player)
    prior_season_score_for(player)&.points
  end

  def prior_season_score_for(player)
    player.league_score(league:, season: league.season - 1)
  end

  def pick_timer_paused?
    pick_timer_paused_at.present?
  end

  def current_pick_elapsed_seconds(now: Time.current)
    pick_started_at = picks.last&.created_at || started_at
    return 0 unless pick_started_at

    stopped_at = pick_timer_paused_at || now
    [ (stopped_at - pick_started_at).floor - pick_timer_paused_seconds, 0 ].max
  end

  def pause_pick_timer!
    with_lock do
      raise ActiveRecord::RecordInvalid, self unless live?

      update!(pick_timer_paused_at: Time.current) unless pick_timer_paused?
    end
  end

  def resume_pick_timer!
    with_lock do
      return unless pick_timer_paused?

      paused_for = (Time.current - pick_timer_paused_at).floor
      update!(pick_timer_paused_at: nil, pick_timer_paused_seconds: pick_timer_paused_seconds + paused_for)
    end
  end

  def start!
    raise ActiveRecord::RecordInvalid, self if draft_entries.empty?

    update!(status: :live, started_at: Time.current)
  end

  private

  def scheduled_start_changed?
    setup? && saved_change_to_scheduled_start_at? && scheduled_start_at.present?
  end

  def enqueue_scheduled_start
    StartScheduledDraftJob.set(wait_until: scheduled_start_at).perform_later(self)
  end

  def set_rounds_from_roster
    self.rounds = roster_size if roster_size.positive?
  end

  def assign_public_id
    self.public_id ||= SecureRandom.urlsafe_base64(9)
  end
end
