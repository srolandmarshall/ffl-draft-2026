require "json"
require "net/http"

module DataSources
  module Espn
    class Client
      BASE_URL = "https://lm-api-reads.fantasy.espn.com/apis/v3/games/ffl/seasons".freeze
      PlayerScore = Data.define(:espn_id, :points, :stats)

      def initialize(fetcher: nil, espn_s2: ENV["ESPN_S2"], swid: ENV["ESPN_SWID"])
        @fetcher = fetcher || method(:get)
        @espn_s2 = espn_s2
        @swid = swid
      end

      def fetch_players(year:)
        fetch(players_uri(year:))
      end

      def fetch_league_settings(year:, league_id:)
        LeagueSettings.from_payload(fetch(league_settings_uri(year:, league_id:)))
      end

      def fetch_league_snapshot(year:, league_id:)
        payload = fetch(league_snapshot_uri(year:, league_id:))
        payload = payload.first if payload.is_a?(Array)
        LeagueSnapshot.from_payload(payload)
      end

      def fetch_player_scores(year:, league_id:)
        payload = fetch(league_player_scores_uri(year:, league_id:))
        scores = payload.fetch("players", []).filter_map do |entry|
          player = entry.fetch("player", entry)
          stat = Array(player["stats"]).find do |candidate|
            candidate["seasonId"].to_i == year.to_i &&
              candidate["scoringPeriodId"].to_i.zero? &&
              candidate["statSourceId"].to_i.zero? &&
              candidate["statSplitTypeId"].to_i.zero?
          end
          if stat&.key?("appliedTotal")
            PlayerScore.new(
              espn_id: player.fetch("id").to_i,
              points: BigDecimal(stat.fetch("appliedTotal").to_s),
              stats: stat.fetch("stats", {})
            )
          end
        end
        raise HttpError, "ESPN returned no league-scored player totals for #{year}" if scores.empty?

        scores
      end

      private

      attr_reader :fetcher, :espn_s2, :swid

      def fetch(uri)
        parse(fetcher.call(uri))
      rescue SocketError, Timeout::Error, Errno::ECONNREFUSED => error
        raise HttpError, "ESPN is unavailable: #{error.message}"
      end

      def parse(response)
        if [ 401, 403 ].include?(response.code.to_i)
          raise HttpError, "ESPN denied access. Use Connect private league to provide your ESPN cookies."
        end
        raise HttpError, "ESPN returned HTTP #{response.code}" unless response.code.to_i.between?(200, 299)

        JSON.parse(response.body)
      rescue JSON::ParserError => error
        raise HttpError, "ESPN returned invalid JSON: #{error.message}"
      end

      def players_uri(year:)
        uri = URI("#{BASE_URL}/#{Integer(year)}/players")
        uri.query = URI.encode_www_form(view: "players_wl")
        uri
      end

      def league_settings_uri(year:, league_id:)
        uri = URI("#{BASE_URL}/#{Integer(year)}/segments/0/leagues/#{Integer(league_id)}")
        uri.query = URI.encode_www_form(view: "mSettings")
        uri
      end

      def league_snapshot_uri(year:, league_id:)
        year = Integer(year)
        league_id = Integer(league_id)
        uri = if year < 2018
          URI("https://lm-api-reads.fantasy.espn.com/apis/v3/games/ffl/leagueHistory/#{league_id}")
        else
          URI("#{BASE_URL}/#{year}/segments/0/leagues/#{league_id}")
        end
        uri.query = URI.encode_www_form(seasonId: year) if year < 2018
        existing_query = URI.decode_www_form(uri.query.to_s)
        uri.query = URI.encode_www_form(existing_query + %w[mTeam mSettings mDraftDetail mStandings].map { |view| [ "view", view ] })
        uri
      end

      def league_player_scores_uri(year:, league_id:)
        uri = URI("#{BASE_URL}/#{Integer(year)}/segments/0/leagues/#{Integer(league_id)}")
        uri.query = URI.encode_www_form(view: "kona_player_info")
        uri
      end

      def get(uri)
        request = Net::HTTP::Get.new(uri)
        if URI.decode_www_form(uri.query.to_s).include?([ "view", "kona_player_info" ])
          request["x-fantasy-filter"] = {
            players: {
              limit: 3000,
              sortPercOwned: { sortPriority: 1, sortAsc: false }
            }
          }.to_json
        elsif uri.path.end_with?("/players")
          request["x-fantasy-filter"] = { filterActive: { value: true } }.to_json
        end
        request["Cookie"] = "espn_s2=#{espn_s2}; SWID=#{swid}" if espn_s2.present? && swid.present?
        Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }
      end
    end
  end
end
