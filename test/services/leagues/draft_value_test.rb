require "test_helper"

module Leagues
  class DraftValueTest < ActiveSupport::TestCase
    setup do
      @league = leagues(:one)
      @season = espn_seasons(:one)
      @season.update!(season: 2025)
      @franchise = espn_franchises(:one)
      LeaguePlayerScore.delete_all
      EspnDraftPick.delete_all
    end

    test "measures a pick against the positional slot it cost" do
      early = player("Early Back", 901, "RB")
      late = player("Late Back", 902, "RB")
      middle = player("Middle Back", 903, "RB")
      pick(early, overall: 1, round: 1)
      pick(middle, overall: 20, round: 2)
      pick(late, overall: 100, round: 9)
      score(early, 10)
      score(middle, 200)
      score(late, 300)

      picks = DraftValue.new(@league).call.index_by(&:player_name)

      assert_equal 3, picks.size
      assert_equal 3, picks["Early Back"].position_rank
      assert_equal 1, picks["Late Back"].position_rank
    end

    test "surfaces steals and busts by how far a pick moved" do
      early = player("Early Back", 901, "RB")
      middle = player("Middle Back", 903, "RB")
      late = player("Late Back", 902, "RB")
      pick(early, overall: 1, round: 1)
      pick(middle, overall: 20, round: 2)
      pick(late, overall: 100, round: 9)
      score(early, 10)
      score(middle, 200)
      score(late, 300)

      value = DraftValue.new(@league)

      assert_equal "Late Back", value.steals.first.player_name
      assert_equal 2, value.steals.first.value_over_draft
      assert_equal "Early Back", value.busts.first.player_name
      assert_equal(-2, value.busts.first.value_over_draft)
    end

    test "ignores positions with too few picks to rank" do
      solo = player("Only Kicker", 910, "K")
      pick(solo, overall: 5, round: 1)
      score(solo, 100)

      assert_empty DraftValue.new(@league).steals
    end

    private

    def player(name, espn_id, position)
      Player.create!(name:, espn_id:, position:, pro_team: "KC", active: false)
    end

    def pick(player, overall:, round:)
      @season.draft_picks.create!(
        espn_franchise: @franchise, overall_number: overall, round:, round_pick: overall,
        espn_team_id: 1, team_name: "Team", team_abbreviation: "TM",
        espn_player_id: player.espn_id, player_name: player.name, position: player.position
      )
    end

    def score(player, points)
      LeaguePlayerScore.create!(league: @league, player:, season: @season.season, points:)
    end
  end
end
