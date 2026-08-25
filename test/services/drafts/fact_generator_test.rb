require "test_helper"

class Drafts::FactGeneratorTest < ActiveSupport::TestCase
  test "ranks a curated set of current draft superlatives" do
    draft = drafts(:one)
    second_team = draft.league.teams.create!(name: "Green Foxes", owner_name: "Morgan", abbreviation: "GRN")
    draft.draft_entries.create!(team: second_team, position: 2)
    player_data = [
      [ "Avery Arm", "QB", "ATL" ],
      [ "Wren Wideout", "WR", "ATL" ],
      [ "Riley Runner", "RB", "BUF" ],
      [ "Taylor Runner", "RB", "BUF" ],
      [ "Casey Catcher", "TE", "SEA" ],
      [ "Dallas Defense", "DST", "DAL" ]
    ]
    drafted_players = player_data.map.with_index do |(name, position, pro_team), index|
      Player.create!(name:, position:, pro_team:, ranking: index + 1)
    end
    elapsed = [ 12, 35, 18, 95, 24, 42 ]
    now = Time.current
    Pick.insert_all!(drafted_players.map.with_index do |player, index|
      {
        draft_id: draft.id,
        team_id: index.in?([ 0, 1, 4 ]) ? teams(:one).id : second_team.id,
        player_id: player.id,
        round: (index / 2) + 1,
        overall_number: index + 1,
        elapsed_seconds: elapsed[index],
        created_at: now,
        updated_at: now
      }
    end)

    facts = Drafts::FactGenerator.new(draft:, picks: draft.picks.to_a).call
    titles = facts.map(&:title)

    assert_operator facts.size, :<=, 12
    assert_includes titles, "Longest on the Clock"
    assert_includes titles, "Biggest Position Run"
    assert_includes titles, "NFL Team Favorite"
    assert_includes titles, "Stack City"
    assert facts.each_cons(2).all? { |left, right| left.score >= right.score }
  end

  test "uses ESPN history for repeat-player facts but not timing facts" do
    draft = drafts(:one)
    player = Player.create!(name: "MyString", position: "QB", pro_team: "ATL", ranking: 1)
    draft.picks.create!(team: teams(:one), player:, round: 1, overall_number: 2, elapsed_seconds: 40)
    espn_draft_picks(:one).update!(espn_franchise: espn_franchises(:one))

    facts = Drafts::FactGenerator.new(draft:, picks: draft.picks.to_a).call
    historical_facts = facts.select(&:historical)

    assert_includes historical_facts.map(&:title), "My Guy"
    assert_includes historical_facts.map(&:title), "Déjà Vu"
    assert historical_facts.none? { |fact| fact.type == :timing }
  end
end
