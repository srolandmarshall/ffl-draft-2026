require "csv"
require "net/http"
require "stringio"

module DataSources
  module Nflverse
    class Client
      DownloadedImage = Data.define(:io, :content_type, :extension)
      PLAYERS_URL = "https://github.com/nflverse/nflverse-data/releases/download/players/players.csv".freeze
      STATS_URL = "https://github.com/nflverse/nflverse-data/releases/download/stats_player/stats_player_reg_%<year>d.csv".freeze
      MAX_REDIRECTS = 5

      def initialize(fetcher: nil)
        @fetcher = fetcher || method(:get)
      end

      def fetch_players
        parse(fetcher.call(URI(PLAYERS_URL)))
      end

      def fetch_actual_stats(year:)
        parse(fetcher.call(URI(format(STATS_URL, year: Integer(year)))))
      end

      def fetch_headshot(url:)
        response = fetcher.call(URI(url))
        raise HttpError, "NFL headshot returned HTTP #{response.code}" unless response.code.to_i.between?(200, 299)

        content_type = response["content-type"].to_s.split(";").first.presence || "image/jpeg"
        extension = { "image/png" => "png", "image/webp" => "webp" }.fetch(content_type, "jpg")
        DownloadedImage.new(io: StringIO.new(response.body), content_type:, extension:)
      end

      private

      attr_reader :fetcher

      def parse(response)
        raise HttpError, "nflverse returned HTTP #{response.code}" unless response.code.to_i.between?(200, 299)

        CSV.parse(response.body, headers: true)
      rescue CSV::MalformedCSVError => error
        raise HttpError, "nflverse returned invalid CSV: #{error.message}"
      end

      def get(uri, redirects: MAX_REDIRECTS)
        response = Net::HTTP.get_response(uri)
        return response unless response.is_a?(Net::HTTPRedirection)
        raise HttpError, "nflverse redirected too many times" if redirects.zero?

        get(URI.join(uri, response.fetch("location")), redirects: redirects - 1)
      rescue SocketError, Timeout::Error, Errno::ECONNREFUSED => error
        raise HttpError, "nflverse is unavailable: #{error.message}"
      end
    end
  end
end
