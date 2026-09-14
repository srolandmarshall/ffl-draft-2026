module Mcp
  class Oauth
    SCOPE = "league:read"
    ACCESS_TOKEN_LIFETIME = 1.hour
    REFRESH_TOKEN_LIFETIME = 180.days
    AUTHORIZATION_CODE_LIFETIME = 5.minutes

    class Error < StandardError
      attr_reader :code, :description, :status

      def initialize(code, description, status: :bad_request)
        @code = code
        @description = description
        @status = status
        super(description)
      end
    end

    class << self
      def protected_resource_metadata(base_url)
        {
          resource: resource_url(base_url),
          authorization_servers: [base_url],
          scopes_supported: [SCOPE],
          bearer_methods_supported: ["header"],
          resource_documentation: "#{base_url}/#mcp-oauth"
        }
      end

      def authorization_server_metadata(base_url)
        {
          issuer: base_url,
          authorization_endpoint: "#{base_url}/oauth/authorize",
          token_endpoint: "#{base_url}/oauth/token",
          registration_endpoint: "#{base_url}/oauth/register",
          response_types_supported: ["code"],
          grant_types_supported: %w[authorization_code refresh_token],
          code_challenge_methods_supported: ["S256"],
          token_endpoint_auth_methods_supported: ["none"],
          scopes_supported: [SCOPE],
          authorization_response_iss_parameter_supported: true
        }
      end

      def www_authenticate(base_url)
        metadata_url = "#{base_url}/.well-known/oauth-protected-resource"
        %(Bearer resource_metadata="#{metadata_url}", scope="#{SCOPE}")
      end

      def register_client(params)
        redirect_uris = Array(params["redirect_uris"])
        raise Error.new("invalid_client_metadata", "redirect_uris is required") if redirect_uris.empty?
        unless redirect_uris.all? { |uri| secure_redirect_uri?(uri) }
          raise Error.new("invalid_redirect_uri", "redirect URIs must use HTTPS")
        end

        token_auth_method = params["token_endpoint_auth_method"].presence || "none"
        unless token_auth_method == "none"
          raise Error.new("invalid_client_metadata", "only public PKCE clients are supported")
        end

        metadata = {
          "redirect_uris" => redirect_uris,
          "client_name" => params["client_name"].presence || "MCP client",
          "grant_types" => %w[authorization_code refresh_token],
          "response_types" => ["code"],
          "token_endpoint_auth_method" => "none",
          "issued_at" => Time.current.to_i
        }
        client_id = verifier(:client).generate(metadata)

        metadata.merge(
          "client_id" => client_id,
          "client_id_issued_at" => metadata.fetch("issued_at")
        )
      end

      def authorization_request(params, base_url)
        client_id = params["client_id"].to_s
        client = verified_client(client_id)
        redirect_uri = params["redirect_uri"].to_s
        validate_redirect_uri!(client, redirect_uri)
        validate_authorization_parameters!(params, base_url)

        payload = {
          "client_id" => client_id,
          "client_name" => client.fetch("client_name"),
          "redirect_uri" => redirect_uri,
          "resource" => params["resource"],
          "scope" => normalized_scope(params["scope"]),
          "state" => params["state"].to_s,
          "code_challenge" => params["code_challenge"],
          "created_at" => Time.current.to_i,
          "issuer" => base_url
        }

        {
          token: verifier(:request).generate(payload, expires_in: 10.minutes),
          client_name: payload.fetch("client_name"),
          scope: payload.fetch("scope")
        }
      end

      def complete_authorization(request_token, user:, approved:)
        payload = verifier(:request).verify(request_token)

        unless approved
          return redirect_with(
            payload.fetch("redirect_uri"),
            error: "access_denied",
            state: payload["state"],
            iss: payload.fetch("issuer")
          )
        end

        code_metadata = payload.slice(
          "client_id", "redirect_uri", "resource", "scope", "code_challenge", "issuer"
        )
        code = ApiToken.issue!(
          user:,
          label: encoded_label("oauth_code:", code_metadata),
          expires_in: AUTHORIZATION_CODE_LIFETIME,
          token_prefix: "ffld_code_"
        )

        redirect_with(
          payload.fetch("redirect_uri"),
          code:,
          state: payload["state"],
          iss: payload.fetch("issuer")
        )
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        raise Error.new("invalid_request", "authorization request is invalid or expired")
      end

      def exchange_token(params, base_url)
        case params["grant_type"]
        when "authorization_code"
          exchange_authorization_code(params, base_url)
        when "refresh_token"
          exchange_refresh_token(params, base_url)
        else
          raise Error.new("unsupported_grant_type", "unsupported grant_type")
        end
      end

      private

      def exchange_authorization_code(params, base_url)
        client_id = params["client_id"].to_s
        verified_client(client_id)
        metadata, user = consume_token!(params["code"], "oauth_code:")
        validate_token_context!(metadata, params, client_id, base_url)
        verify_pkce!(metadata.fetch("code_challenge"), params["code_verifier"].to_s)
        issue_token_pair(user:, client_id:, resource: metadata.fetch("resource"), scope: metadata.fetch("scope"))
      end

      def exchange_refresh_token(params, base_url)
        client_id = params["client_id"].to_s
        verified_client(client_id)
        metadata, user = consume_token!(params["refresh_token"], "oauth_refresh:")
        validate_token_context!(metadata, params, client_id, base_url)
        issue_token_pair(user:, client_id:, resource: metadata.fetch("resource"), scope: metadata.fetch("scope"))
      end

      def issue_token_pair(user:, client_id:, resource:, scope:)
        metadata = {
          "client_id_digest" => Digest::SHA256.hexdigest(client_id),
          "resource" => resource,
          "scope" => scope
        }
        access_token = ApiToken.issue!(
          user:,
          label: encoded_label("oauth_access:", metadata),
          expires_in: ACCESS_TOKEN_LIFETIME,
          token_prefix: "ffld_oauth_"
        )
        refresh_token = ApiToken.issue!(
          user:,
          label: encoded_label("oauth_refresh:", metadata),
          expires_in: REFRESH_TOKEN_LIFETIME,
          token_prefix: "ffld_refresh_"
        )

        {
          access_token:,
          token_type: "Bearer",
          expires_in: ACCESS_TOKEN_LIFETIME.to_i,
          refresh_token:,
          scope:
        }
      end

      def consume_token!(raw_token, label_prefix)
        token = ApiToken.find_by_raw_token(raw_token)
        raise Error.new("invalid_grant", "token is invalid or expired", status: :unauthorized) unless token

        metadata = nil
        token.with_lock do
          unless token.active? && token.label.to_s.start_with?(label_prefix)
            raise Error.new("invalid_grant", "token is invalid or expired", status: :unauthorized)
          end

          metadata = decoded_label(token.label, label_prefix)
          token.revoke!
        end
        [metadata, token.user]
      end

      def validate_token_context!(metadata, params, client_id, base_url)
        requested_resource = params["resource"].to_s
        expected_resource = resource_url(base_url)
        unless requested_resource == expected_resource && metadata.fetch("resource") == expected_resource
          raise Error.new("invalid_target", "resource does not match this MCP server")
        end

        digest = metadata["client_id_digest"] || Digest::SHA256.hexdigest(metadata.fetch("client_id"))
        unless secure_equal?(digest, Digest::SHA256.hexdigest(client_id))
          raise Error.new("invalid_grant", "client_id does not match the grant")
        end

        if params["redirect_uri"].present? && metadata["redirect_uri"] != params["redirect_uri"]
          raise Error.new("invalid_grant", "redirect_uri does not match the grant")
        end
      end

      def validate_authorization_parameters!(params, base_url)
        unless params["response_type"] == "code"
          raise Error.new("unsupported_response_type", "response_type must be code")
        end
        unless params["resource"] == resource_url(base_url)
          raise Error.new("invalid_target", "resource does not match this MCP server")
        end
        unless normalized_scope(params["scope"]) == SCOPE
          raise Error.new("invalid_scope", "scope must be #{SCOPE}")
        end
        unless params["code_challenge_method"] == "S256" && params["code_challenge"].present?
          raise Error.new("invalid_request", "PKCE with S256 is required")
        end
      end

      def verify_pkce!(challenge, verifier_value)
        computed = Base64.urlsafe_encode64(
          Digest::SHA256.digest(verifier_value),
          padding: false
        )
        return if secure_equal?(challenge, computed)

        raise Error.new("invalid_grant", "PKCE verification failed", status: :unauthorized)
      end

      def verified_client(client_id)
        verifier(:client).verify(client_id)
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        raise Error.new("invalid_client", "client_id is invalid", status: :unauthorized)
      end

      def validate_redirect_uri!(client, redirect_uri)
        return if client.fetch("redirect_uris").include?(redirect_uri)

        raise Error.new("invalid_redirect_uri", "redirect_uri is not registered")
      end

      def normalized_scope(scope)
        scope.to_s.split.uniq.sort.join(" ").presence || SCOPE
      end

      def resource_url(base_url)
        "#{base_url}/mcp"
      end

      def secure_redirect_uri?(value)
        uri = URI.parse(value.to_s)
        uri.is_a?(URI::HTTPS) && uri.fragment.nil?
      rescue URI::InvalidURIError
        false
      end

      def redirect_with(location, values)
        uri = URI.parse(location)
        current = Rack::Utils.parse_nested_query(uri.query)
        query = current.merge(values.compact.transform_values(&:to_s))
        uri.query = Rack::Utils.build_query(query)
        uri.to_s
      end

      def encoded_label(prefix, metadata)
        "#{prefix}#{Base64.urlsafe_encode64(metadata.to_json, padding: false)}"
      end

      def decoded_label(label, prefix)
        JSON.parse(Base64.urlsafe_decode64(label.delete_prefix(prefix)))
      rescue JSON::ParserError, ArgumentError
        raise Error.new("invalid_grant", "token metadata is invalid", status: :unauthorized)
      end

      def secure_equal?(left, right)
        return false unless left.bytesize == right.bytesize

        ActiveSupport::SecurityUtils.secure_compare(left, right)
      end

      def verifier(purpose)
        Rails.application.message_verifier("mcp-oauth-#{purpose}")
      end
    end
  end
end
