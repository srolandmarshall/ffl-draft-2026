# Preview all emails at http://localhost:3000/rails/mailers/login_code_mailer
class LoginCodeMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/login_code_mailer/login_code
  def login_code
    LoginCodeMailer.with(user: User.first, code: "123456").login_code
  end
end
