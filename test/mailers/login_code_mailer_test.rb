require "test_helper"

class LoginCodeMailerTest < ActionMailer::TestCase
  test "login_code" do
    mail = LoginCodeMailer.with(user: users(:member), code: "123456").login_code

    assert_equal "Your Fantasy Draft sign-in code", mail.subject
    assert_equal [ users(:member).email ], mail.to
    assert_match "123456", mail.body.encoded
  end
end
