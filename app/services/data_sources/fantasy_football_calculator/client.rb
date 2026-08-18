require "json"
require "net/http"

module DataSources
  module FantasyFootballCalculator
    class Client
      BASE_URL = "https://fantasyfootballcalculator.com".freeze
      SCORING_FORMATS = %w[standard half-ppr ppr 2-qb dynasty rookie].freeze

      def initialize(fetcher: Net::HTTP.method(:get_response))
        @fetcher = fetcher
      end

      def fetch_adp(scoring_format:, teams:, year:)
        validate!(scoring_format:, teams:, year:)
        response = fetcher.call(uri(scoring_format:, teams:, year:))
        raise HttpError, "Fantasy Football Calculator returned HTTP #{response.code}" unless response.code.to_i.between?(200, 299)

        JSON.parse(response.body).tap do |payload|
          raise HttpError, "Fantasy Football Calculator did not return ADP data" unless payload["status"] == "Success"
        end
      rescue JSON::ParserError => error
        raise HttpError, "Fantasy Football Calculator returned invalid JSON: #{error.message}"
      rescue SocketError, Timeout::Error, Errno::ECONNREFUSED => error
        raise HttpError, "Fantasy Football Calculator is unavailable: #{error.message}"
      end

      private

      attr_reader :fetcher

      def uri(scoring_format:, teams:, year:)
        URI("#{BASE_URL}/api/v1/adp/#{scoring_format}?#{URI.encode_www_form(teams:, year:)}")
      end

      def validate!(scoring_format:, teams:, year:)
        raise ArgumentError, "Unknown scoring format" unless SCORING_FORMATS.include?(scoring_format)
        raise ArgumentError, "Team count must be between 8 and 14" unless (8..14).cover?(teams)
        raise ArgumentError, "Year is invalid" unless (2007..Date.current.year).cover?(year)
      end
    end
  end
end
