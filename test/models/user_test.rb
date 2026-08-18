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
end
