require "json"

seed_path = Rails.root.join("db/seeds/fantasy_year_ix.json")
seed_data = JSON.parse(seed_path.read)
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
    owner_name: owners.map { |owner| owner.fetch("name") }.join(" & ")
  )
  team.save!
  team.users = owners.filter_map { |owner| user_for_emails!(owner.fetch("emails")) }
  team
end

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
puts "Seeded #{league.name} (#{league.season}) with #{teams.size} teams, #{email_count} email addresses, and #{league.drafts.count} drafts."
