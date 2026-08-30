require "test_helper"

module DataSources
  module Espn
    class LeagueSyncTest < ActiveSupport::TestCase
      class FakeClient
        attr_reader :snapshot_years

        def initialize(snapshots:, players: { "players" => [] }, player_updates: [], player_scores: [])
          @snapshots = snapshots
          @players = players
          @player_updates = player_updates
          @player_scores = player_scores
          @snapshot_years = []
        end

        def fetch_league_snapshot(year:, league_id:)
          @snapshot_years << year.to_i
          @snapshots.fetch(year.to_i) { raise HttpError, "no snapshot stubbed for #{year}" }
        end

        def fetch_players(year:) = @players.is_a?(Hash) && @players.key?(year.to_i) ? @players.fetch(year.to_i) : @players
        def fetch_player_updates(year:, league_id:) = @player_updates
        def fetch_player_scores(year:, league_id:) = @player_scores.is_a?(Hash) ? @player_scores.fetch(year.to_i) : @player_scores
      end

      setup do
        @league = League.create!(name: "Sync League", season: 2026, espn_league_id: "12345")
      end

      def payload(season:, previous_seasons: [], picks: [], abbreviation: "RED")
        {
          "seasonId" => season,
          "status" => { "previousSeasons" => previous_seasons },
          "members" => [ { "id" => "owner-1", "displayName" => "Riley" } ],
          "teams" => [ { "id" => 1, "abbrev" => abbreviation, "name" => "Red Hawks", "owners" => [ "owner-1" ] } ],
          "settings" => {
            "name" => "ESPN League #{season}",
            "size" => 1,
            "rosterSettings" => { "lineupSlotCounts" => {
              "0" => 1, "2" => 2, "4" => 2, "6" => 1, "3" => 0, "5" => 0, "7" => 0, "23" => 0,
              "16" => 1, "17" => 1, "20" => 6, "21" => 0
            } },
            "scoringSettings" => { "scoringItems" => [ { "statId" => 53, "points" => 1.0 } ] },
            "draftSettings" => { "type" => "SNAKE" }
          },
          "draftDetail" => { "drafted" => true, "picks" => picks }
        }
      end

      def pick(overall:, player_id: 100, team_id: 1)
        { "overallPickNumber" => overall, "roundId" => 1, "roundPickNumber" => overall, "teamId" => team_id, "playerId" => player_id }
      end

      test "imports settings, teams, the current season, and player scores in one pass" do
        player = Player.create!(name: "Some Player", position: "RB", pro_team: "ATL", espn_id: 100)
        current = LeagueSnapshot.from_payload(payload(season: 2026, picks: [ pick(overall: 1) ]))
        client = FakeClient.new(
          snapshots: { 2026 => current },
          player_scores: [ Client::PlayerScore.new(espn_id: 100, points: 12.5, stats: {}) ]
        )

        result = LeagueSync.new(league: @league, client:).call

        assert_equal 1, result.teams_created
        assert_equal 1, result.seasons_imported
        assert_equal [], result.seasons_skipped
        assert_equal 1, result.standings_imported
        assert_equal 0, result.matchups_imported
        assert_equal 1, result.player_scores_imported
        assert_equal 1, @league.reload.qb_slots
        assert_equal 2, @league.rb_slots
        assert_equal @league.espn_seasons.sole.draft_picks.sole.espn_player_id, 100
        assert_equal 1, @league.espn_team_seasons.count
        assert_equal 12.5, LeaguePlayerScore.find_by(league: @league, player:, season: 2025).points
      end

      test "imports historical scores for every synced season and keeps retired players off the draft board" do
        current = LeagueSnapshot.from_payload(payload(season: 2026, previous_seasons: [ 2025 ]))
        historical = LeagueSnapshot.from_payload(payload(season: 2025))
        client = FakeClient.new(
          snapshots: { 2025 => historical, 2026 => current },
          players: { 2025 => [ { "id" => 200, "fullName" => "Retired Player", "defaultPositionId" => 2, "proTeamId" => 0 } ] },
          player_scores: { 2025 => [ Client::PlayerScore.new(espn_id: 200, points: 99.5, stats: {}) ] }
        )

        result = LeagueSync.new(league: @league, client:).call

        player = Player.find_by!(espn_id: 200)
        assert_not player.active?
        assert_nil player.pro_team
        assert_equal 1, result.player_scores_imported
        assert_equal 99.5, LeaguePlayerScore.find_by!(league: @league, player:, season: 2025).points
      end

      test "imports historical identity from oldest to newest" do
        current = LeagueSnapshot.from_payload(payload(season: 2026, previous_seasons: [ 2025, 2024 ], abbreviation: "Y26"))
        season_2025 = LeagueSnapshot.from_payload(payload(season: 2025, abbreviation: "Y25"))
        season_2024 = LeagueSnapshot.from_payload(payload(season: 2024, abbreviation: "Y24"))
        client = FakeClient.new(snapshots: { 2024 => season_2024, 2025 => season_2025, 2026 => current })

        LeagueSync.new(league: @league, client:).call

        assert_equal [ 2026, 2024, 2025 ], client.snapshot_years
        assert_equal %w[Y24 Y25 Y26], @league.espn_franchises.sole.aliases
        assert_equal 3, @league.espn_team_seasons.count
      end

      test "skips a previous season whose fetch fails and still imports the rest" do
        current = LeagueSnapshot.from_payload(payload(season: 2026, previous_seasons: [ 2025, 2024 ]))
        good_previous = LeagueSnapshot.from_payload(payload(season: 2024))
        client = FakeClient.new(snapshots: { 2026 => current, 2024 => good_previous })
        client.define_singleton_method(:fetch_league_snapshot) do |year:, league_id:|
          raise HttpError, "ESPN unavailable" if year.to_i == 2025

          { 2026 => current, 2024 => good_previous }.fetch(year.to_i)
        end

        result = LeagueSync.new(league: @league, client:).call

        assert_equal 2, result.seasons_imported
        assert_equal [ 2025 ], result.seasons_skipped
        assert_equal [ 2024, 2026 ], @league.espn_seasons.pluck(:season).sort
      end

      test "rolls back every change if a draft pick references a team missing from the roster" do
        # teamId 2 doesn't exist in the payload's "teams" list (only id 1 does), so
        # LeagueSnapshot#draft_picks raises KeyError while resolving it - partway through
        # the same transaction that already created the team from mTeam data.
        current = LeagueSnapshot.from_payload(payload(season: 2026, picks: [ pick(overall: 1, team_id: 2) ]))
        client = FakeClient.new(snapshots: { 2026 => current })

        assert_no_difference -> { @league.teams.count } do
          assert_raises(KeyError) do
            LeagueSync.new(league: @league, client:).call
          end
        end
        assert_equal 0, @league.espn_seasons.count
      end

      test "imports fixture standings and matchups without duplicates on rerun" do
        @league.update!(season: 2016)
        payload = JSON.parse(file_fixture("espn/league_snapshot_2016.json").read).first
        snapshot = LeagueSnapshot.from_payload(payload)
        client = FakeClient.new(snapshots: { 2016 => snapshot })

        first = LeagueSync.new(league: @league, client:).call
        second = LeagueSync.new(league: @league, client:).call

        assert_equal 12, first.standings_imported
        assert_equal 97, first.matchups_imported
        assert_equal 12, second.standings_imported
        assert_equal 97, second.matchups_imported
        assert_equal 12, @league.espn_team_seasons.count
        assert_equal 97, EspnMatchup.joins(:espn_season).where(espn_seasons: { league_id: @league.id }).count
      end
    end
  end
end
