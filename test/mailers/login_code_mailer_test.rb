require "test_helper"

class LoginCodeMailerTest < ActionMailer::TestCase
  test "login_code" do
    mail = LoginCodeMailer.with(email: "riley.secondary@example.com", code: "123456").login_code

    assert_equal "Your Fantasy Draft sign-in code", mail.subject
    assert_equal [ "riley.secondary@example.com" ], mail.to
    assert_match "123456", mail.body.encoded
  end
end
