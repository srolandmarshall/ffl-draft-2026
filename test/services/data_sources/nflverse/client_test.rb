# frozen_string_literal: true

require "test_helper"

module DataSources
  module Nflverse
    class ClientTest < ActiveSupport::TestCase
      test "downloads a headshot whose body matches the declared length" do
        client = Client.new(fetcher: ->(_uri) { response(body: "abcde", headers: { "content-length" => "5", "content-type" => "image/png" }) })

        download = client.fetch_headshot(url: "https://example.com/one.png")

        assert_equal "abcde", download.io.read
        assert_equal "image/png", download.content_type
        assert_equal "png", download.extension
      end

      test "refuses a headshot whose body is shorter than Content-Length" do
        # Net::HTTP returns a short body without error when a connection is cut mid-transfer.
        # Attaching that stores a blob whose recorded size never matches its contents.
        client = Client.new(fetcher: ->(_uri) { response(body: "ab", headers: { "content-length" => "5" }) })

        error = assert_raises(HttpError) { client.fetch_headshot(url: "https://example.com/one.png") }

        assert_match(/truncated/, error.message)
        assert_match(/2 of 5/, error.message)
      end

      test "accepts a headshot when the server declares no length" do
        client = Client.new(fetcher: ->(_uri) { response(body: "abcde", headers: {}) })

        assert_equal "abcde", client.fetch_headshot(url: "https://example.com/one.png").io.read
      end

      test "raises for a non-success response" do
        client = Client.new(fetcher: ->(_uri) { response(body: "", code: "404") })

        assert_raises(HttpError) { client.fetch_headshot(url: "https://example.com/one.png") }
      end

      private

      def response(body:, code: "200", headers: {})
        Struct.new(:body, :code, :headers) do
          def [](name) = headers[name]
        end.new(body, code, headers)
      end
    end
  end
end
