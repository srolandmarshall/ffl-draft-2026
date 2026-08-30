module DataSources
  module Espn
    class Client
      class LeagueEndpoint
        def initialize(year:, league_id:)
          @year = Integer(year)
          @league_id = Integer(league_id)
        end

        def uri(views:)
          request_uri.query = URI.encode_www_form(query(views))
          request_uri
        end

        private

        attr_reader :year, :league_id

        def request_uri
          @request_uri ||= if year < 2018
            URI("https://lm-api-reads.fantasy.espn.com/apis/v3/games/ffl/leagueHistory/#{league_id}")
          else
            URI("#{Client::BASE_URL}/#{year}/segments/0/leagues/#{league_id}")
          end
        end

        def query(views)
          [ *(year < 2018 ? [ [ "seasonId", year ] ] : []), *views.map { |view| [ "view", view ] } ]
        end
      end
    end
  end
end
