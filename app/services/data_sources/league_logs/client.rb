require "json"
require "net/http"

module DataSources
  module LeagueLogs
    class Client
      BASE_URL = "https://developer.leaguelogs.com".freeze

      def initialize(fetcher: Net::HTTP.method(:get_response))
        @fetcher = fetcher
      end

      def fetch_players
        fetch("/v1/players")
      end

      def fetch_market(profile:)
        fetch("/v1/market/#{profile}")
      end

      private

      attr_reader :fetcher

      def fetch(path)
        response = fetcher.call(URI.join(BASE_URL, path))
        raise HttpError, "LeagueLogs returned HTTP #{response.code}" unless response.code.to_i.between?(200, 299)

        JSON.parse(response.body)
      rescue JSON::ParserError => error
        raise HttpError, "LeagueLogs returned invalid JSON: #{error.message}"
      rescue SocketError, Timeout::Error, Errno::ECONNREFUSED => error
        raise HttpError, "LeagueLogs is unavailable: #{error.message}"
      end
    end
  end
end
