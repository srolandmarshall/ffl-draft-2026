require "test_helper"

module DataSources
  module LeagueLogs
    class ClientTest < ActiveSupport::TestCase
      Response = Data.define(:code, :body)

      test "fetches players and a market profile" do
        requested_paths = []
        client = Client.new(fetcher: lambda { |uri|
          requested_paths << uri.path
          Response.new(code: "200", body: { data: [], meta: {} }.to_json)
        })

        assert_equal [], client.fetch_players.fetch("data")
        assert_equal [], client.fetch_market(profile: "redraft-1qb-12t-ppr1").fetch("data")
        assert_equal [ "/v1/players", "/v1/market/redraft-1qb-12t-ppr1" ], requested_paths
      end

      test "wraps HTTP and JSON failures" do
        unavailable = Client.new(fetcher: ->(_uri) { Response.new(code: "503", body: "nope") })
        invalid = Client.new(fetcher: ->(_uri) { Response.new(code: "200", body: "nope") })

        assert_raises(HttpError) { unavailable.fetch_players }
        assert_raises(HttpError) { invalid.fetch_players }
      end
    end
  end
end
