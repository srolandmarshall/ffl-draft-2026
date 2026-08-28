require "json"

# Real league data (member names and email addresses) is never committed. Drop
# a private JSON file into db/seeds/ under any name — .gitignore excludes
# db/seeds/*.json — or point SEED_DATA at a copy elsewhere, and this script uses
# it. With no such file, it seeds an equivalent league of placeholder teams so a
# fresh clone still has something to draft with.
PLACEHOLDER_TEAM_COUNT = 10

def private_seed_path
  if (configured = ENV["SEED_DATA"].presence)
    path = Pathname.new(configured).then { |candidate| candidate.absolute? ? candidate : Rails.root.join(candidate) }
    abort "SEED_DATA is set to #{configured}, but no file exists there." unless path.exist?
    return path
  end

  candidates = Rails.root.glob("db/seeds/*.json").sort
  if candidates.size > 1
    names = candidates.map { |candidate| candidate.relative_path_from(Rails.root) }.join(", ")
    abort "Found more than one seed file (#{names}). Set SEED_DATA to choose one."
  end

  candidates.first
end

def placeholder_seed_data(team_count)
  {
    "league" => {
      "name" => "Example League",
      "draft_name" => "Live Draft",
      "test_draft_name" => "TEST DRAFT",
      "scheduled_start_at" => 1.week.from_now.iso8601,
      "settings" => {
        "ppr" => 0.5, "draft_type" => "snake",
        "qb_slots" => 1, "rb_slots" => 2, "wr_slots" => 2, "te_slots" => 1,
        "flex_slots" => 2, "k_slots" => 1, "dst_slots" => 1, "bench_slots" => 6
      }
    },
    "commissioner_emails" => [ "commissioner@example.com" ],
    "teams" => (1..team_count).map do |position|
      {
        "position" => position,
        "abbreviation" => format("T%02d", position),
        "name" => "Team #{position}",
        "owners" => [ { "name" => "Manager #{position}", "emails" => [ "manager#{position}@example.com" ] } ]
      }
    end
  }
end

seed_path = private_seed_path
using_placeholders = seed_path.nil?
seed_data = using_placeholders ? placeholder_seed_data(PLACEHOLDER_TEAM_COUNT) : JSON.parse(seed_path.read)

league_data = seed_data.fetch("league")
team_data = seed_data.fetch("teams").sort_by { |team| team.fetch("position") }
season = ENV.fetch("LEAGUE_SEASON", Date.current.year).to_i

def user_for_emails!(emails)
  normalized_emails = emails.map { |email| email.strip.downcase }.uniq
  return if normalized_emails.empty?

  matching_users = normalized_emails.filter_map { |email| User.find_by_any_email(email) }.uniq
  user = matching_users.find { |candidate| candidate.email == normalized_emails.first } || matching_users.first
  user ||= User.create!(email: normalized_emails.first)

  (matching_users - [ user ]).each do |duplicate|
    user.update!(role: :commissioner) if duplicate.commissioner?
    duplicate.team_ids.each { |team_id| user.team_memberships.find_or_create_by!(team_id:) }
    duplicate.destroy!
  end

  normalized_emails.each { |email| user.user_emails.find_or_create_by!(email:) }
  user
end

def seed_draft_entries!(draft, teams)
  return unless draft.picks.empty?

  draft.draft_entries.delete_all
  teams.each.with_index(1) do |team, position|
    draft.draft_entries.create!(team:, position:)
  end
end

league = League.find_or_initialize_by(name: league_data.fetch("name"), season:)
league.assign_attributes(league_data.fetch("settings"))
league.save!

teams = team_data.map do |team_attributes|
  owners = team_attributes.fetch("owners")
  team = league.teams.find_by(name: team_attributes.fetch("name")) ||
    league.teams.find_by(draft_order: team_attributes.fetch("position")) ||
    league.teams.new
  team.assign_attributes(
    name: team_attributes.fetch("name"),
    abbreviation: team_attributes.fetch("abbreviation"),
    draft_order: team_attributes.fetch("position"),
    owner_name: owners.map { |owner| owner.fetch("name") }.join(" & "),
    archived: false
  )
  team.save!
  team.users = owners.filter_map { |owner| user_for_emails!(owner.fetch("emails")) }
  team
end

league.teams.where.not(id: teams.map(&:id)).update_all(archived: true)

commissioner = user_for_emails!(seed_data.fetch("commissioner_emails"))
commissioner.update!(role: :commissioner)

draft = league.drafts.find_or_initialize_by(name: league_data.fetch("draft_name"))
draft.assign_attributes(
  league.draft_defaults.merge(
    team_count: teams.size,
    status: :setup,
    scheduled_start_at: Time.zone.parse(league_data.fetch("scheduled_start_at"))
  )
)
draft.save!
seed_draft_entries!(draft, teams)

test_draft = league.drafts.find_or_initialize_by(name: league_data.fetch("test_draft_name"))
test_draft.assign_attributes(
  league.draft_defaults.merge(
    team_count: teams.size,
    rounds: league.roster_size,
    status: :live,
    scheduled_start_at: nil,
    started_at: test_draft.started_at || Time.current
  )
)
test_draft.save!
seed_draft_entries!(test_draft, teams)

email_count = team_data.sum { |team| team.fetch("owners").sum { |owner| owner.fetch("emails").size } }
source = using_placeholders ? "placeholder data" : seed_path.to_s.delete_prefix("#{Rails.root}/")
puts "Seeded #{league.name} (#{league.season}) from #{source}: #{teams.size} teams, #{email_count} email addresses, #{league.drafts.count} drafts."
puts "No private seed file found — using placeholders. Drop one in db/seeds/ or set SEED_DATA to seed real data." if using_placeholders
