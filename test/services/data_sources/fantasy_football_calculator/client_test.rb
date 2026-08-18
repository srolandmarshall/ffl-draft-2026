require "test_helper"

module DataSources
  module FantasyFootballCalculator
    class ClientTest < ActiveSupport::TestCase
      Response = Data.define(:code, :body)

      test "requests the selected format, league size, and year" do
        requested_uri = nil
        fetcher = lambda do |uri|
          requested_uri = uri
          Response.new(code: "200", body: '{"status":"Success","players":[]}')
        end

        Client.new(fetcher:).fetch_adp(scoring_format: "ppr", teams: 12, year: 2026)

        assert_equal "/api/v1/adp/ppr", requested_uri.path
        assert_equal({ "teams" => "12", "year" => "2026" }, Rack::Utils.parse_query(requested_uri.query))
      end

      test "rejects an invalid scoring format without making a request" do
        assert_raises(ArgumentError) do
          Client.new(fetcher: ->(*) { flunk }).fetch_adp(scoring_format: "banana", teams: 12, year: 2026)
        end
      end
    end
  end
end
