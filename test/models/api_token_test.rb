require "test_helper"

class ApiTokenTest < ActiveSupport::TestCase
  test "issue returns a raw token that can be authenticated" do
    raw_token = ApiToken.issue!(user: users(:member), label: "Draft helper")

    assert raw_token.start_with?(ApiToken::TOKEN_PREFIX)
    token = ApiToken.find_by_raw_token(raw_token)
    assert_equal users(:member), token.user
    assert_equal "Draft helper", token.label
    assert_in_delta 2.hours.from_now.to_i, token.expires_at.to_i, 2
  end

  test "expired and revoked tokens cannot be authenticated" do
    raw_token = ApiToken.issue!(user: users(:member), expires_in: -1.minute)
    assert_nil ApiToken.find_by_raw_token(raw_token)

    raw_token = ApiToken.issue!(user: users(:member))
    ApiToken.find_by_raw_token(raw_token).revoke!
    assert_nil ApiToken.find_by_raw_token(raw_token)
  end
end
