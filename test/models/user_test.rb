require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes email addresses" do
    user = User.create!(email: "  Person@Example.COM ")

    assert_equal "person@example.com", user.email
  end

  test "rejects invalid email addresses" do
    user = User.new(email: "not-an-email")

    assert_not user.valid?
    assert user.errors.added?(:email, :invalid, value: "not-an-email")
  end

  test "finds the same user by any associated email" do
    user = users(:member)
    user.user_emails.create!(email: "riley.secondary@example.com")

    assert_equal user, User.find_by_any_email(" RILEY.SECONDARY@example.com ")
  end

  test "find or create does not duplicate a user when given an alias" do
    user = users(:member)
    user.user_emails.create!(email: "riley.secondary@example.com")

    assert_no_difference("User.count") do
      assert_equal user, User.find_or_create_by_any_email!("riley.secondary@example.com")
    end
  end

  test "a login code is single-use" do
    user = users(:member)
    code = user.issue_login_code!(code: "123456")

    assert user.verify_login_code!(code)
    assert_not user.verify_login_code!(code)
  end

  test "an expired login code cannot sign in" do
    user = users(:member)
    user.issue_login_code!(code: "123456")
    user.update!(login_code_expires_at: 1.second.ago)

    assert_not user.verify_login_code!("123456")
  end

  test "only commissioners and team members may sign in" do
    assert users(:commissioner).allowed_to_sign_in?
    assert users(:member).allowed_to_sign_in?
    assert_not User.create!(email: "unassigned@example.com").allowed_to_sign_in?
  end
end
