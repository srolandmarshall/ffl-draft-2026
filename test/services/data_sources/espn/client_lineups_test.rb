require "test_helper"

module DataSources
  module Espn
    class ClientLineupsTest < ActiveSupport::TestCase
      test "requests the ESPN roster view for a scoring period" do
        requested_uri = nil
        response = Struct.new(:code, :body).new("200", file_fixture("espn/league_lineups.json").read)
        client = Client.new(fetcher: ->(uri) { requested_uri = uri; response })

        snapshot = client.fetch_league_lineups(year: 2026, league_id: 123_456, scoring_period: 3)

        query = URI.decode_www_form(requested_uri.query).to_h
        assert_equal "/apis/v3/games/ffl/seasons/2026/segments/0/leagues/123456", requested_uri.path
        assert_equal "mRoster", query.fetch("view")
        assert_equal "3", query.fetch("scoringPeriodId")
        assert_equal 2, snapshot.teams.size
      end

      test "lets ESPN select the current scoring period when omitted" do
        requested_uri = nil
        response = Struct.new(:code, :body).new("200", file_fixture("espn/league_lineups.json").read)
        client = Client.new(fetcher: ->(uri) { requested_uri = uri; response })

        snapshot = client.fetch_league_lineups(year: 2026, league_id: 123_456)

        assert_nil URI.decode_www_form(requested_uri.query).to_h["scoringPeriodId"]
        assert_equal 3, snapshot.scoring_period
      end
    end
  end
end
