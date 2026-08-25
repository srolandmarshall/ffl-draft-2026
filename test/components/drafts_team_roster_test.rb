# frozen_string_literal: true

require "test_helper"

class Components::Drafts::TeamRosterTest < ActiveSupport::TestCase
  test "renders an empty manager roster" do
    html = render_roster

    assert_includes html, "Team Rosters"
    assert_includes html, teams(:one).name
    assert_includes html, "0 of #{drafts(:one).roster_size} roster slots filled"
    assert_equal drafts(:one).roster_size, html.scan(/data-roster-slot=/).size
    assert_equal drafts(:one).roster_size, html.scan(/style="height: 3.5rem"/).size
    assert_equal drafts(:one).roster_size, html.scan(/data-roster-filled="false"/).size
    assert_includes html, "Starting lineup"
    assert_includes html, "Bench"
    refute_includes html, "Choose roster team"
  end

  test "groups drafted players with pick details without pick time" do
    pick = drafts(:one).picks.create!(team: teams(:one), player: players(:one), round: 1, overall_number: 1, elapsed_seconds: 61)
    players(:one).headshot.attach(io: StringIO.new("headshot"), filename: "headshot.png", content_type: "image/png")
    html = render_roster(picks: [ pick ])

    assert_includes html, players(:one).name
    assert_includes html, "R1 · Pick 1"
    refute_includes html, "Time used for this pick"
    assert_includes html, "data-roster-player-image"
    assert_includes html, "style=\"height: 2.75rem; width: 2.25rem\""
    assert_match(/data-roster-slot="QB"[^>]*data-roster-filled="true"[^>]*data-roster-pick-id="#{pick.id}"/, html)
  end

  test "fills dedicated starters, then flex, then bench in draft order" do
    draft = drafts(:one)
    draft.update!(qb_slots: 1, rb_slots: 1, wr_slots: 1, te_slots: 1, flex_slots: 1, k_slots: 0, dst_slots: 0, bench_slots: 2)
    picks = [
      build_pick(draft, "First Back", "RB", 1),
      build_pick(draft, "Flex Back", "RB", 2),
      build_pick(draft, "Bench Back", "RB", 3),
      build_pick(draft, "Wide Starter", "WR", 4)
    ]

    html = render_roster(picks: picks.reverse)

    assert_slot_contains html, "RB", picks[0]
    assert_slot_contains html, "FLEX", picks[1]
    assert_slot_contains html, "BN 1", picks[2]
    assert_slot_contains html, "WR", picks[3]
    assert_match(/data-roster-slot="QB"[^>]*data-roster-filled="false"/, html)
    assert_match(/data-roster-slot="TE"[^>]*data-roster-filled="false"/, html)
    assert_match(/data-roster-slot="BN 2"[^>]*data-roster-filled="false"/, html)
  end

  test "renders a commissioner team selector" do
    other_team = teams(:one).league.teams.create!(name: "Green Foxes", owner_name: "Morgan", abbreviation: "GRN")
    drafts(:one).draft_entries.create!(team: other_team, position: 2)
    html = render_roster(team: other_team, commissioner: true, preferred_team: teams(:one))

    assert_includes html, "Team Rosters"
    assert_includes html, "Choose roster team"
    assert_includes html, "GRN"
    assert_match(/aria-current="page"[^>]*>GRN</, html)
    assert_operator html.index(">RED</"), :<, html.index(">GRN</")
  end

  private

  def render_roster(team: teams(:one), picks: [], commissioner: false, preferred_team: team)
    ApplicationController.renderer.render(
      Components::Drafts::TeamRoster.new(
        draft: drafts(:one), team:, picks:, commissioner:, preferred_team:
      )
    )
  end

  def build_pick(draft, name, position, overall_number)
    player = Player.create!(name:, position:, pro_team: "ATL", active: true)
    draft.picks.build(id: overall_number, team: teams(:one), player:, round: 1, overall_number:)
  end

  def assert_slot_contains(html, label, pick)
    assert_match(/data-roster-slot="#{Regexp.escape(label)}"[^>]*data-roster-filled="true"[^>]*data-roster-pick-id="#{pick.id}"/, html)
  end
end
