# frozen_string_literal: true

require "test_helper"

class Components::Drafts::UpNextTest < ActiveSupport::TestCase
  test "lists the upcoming teams in order" do
    draft = drafts(:one)
    second_team = draft.league.teams.create!(name: "Green Giants", owner_name: "Greer", abbreviation: "GRN")
    draft.draft_entries.create!(team: second_team, position: 2)

    html = ApplicationController.renderer.render(Components::Drafts::UpNext.new(draft:), layout: false)

    assert_includes html, "Up next"
    assert_includes html, second_team.name
    assert_operator html.index(second_team.name), :<, html.rindex(teams(:one).name)
  end

  test "renders nothing once no more picks remain" do
    draft = drafts(:one)
    draft.picks.create!(team: teams(:one), player: players(:one), round: 1, overall_number: 1)

    html = ApplicationController.renderer.render(Components::Drafts::UpNext.new(draft:), layout: false)

    refute_includes html, "Up next"
  end

  test "renders nothing before the draft is live" do
    draft = drafts(:two)
    draft.league.teams.create!(name: "Green Giants", owner_name: "Greer", abbreviation: "GRN")
    html = ApplicationController.renderer.render(Components::Drafts::UpNext.new(draft:), layout: false)

    refute_includes html, "Up next"
  end
end
