class LoginCodeMailer < ApplicationMailer
  def login_code
    @code = params[:code]

    mail(to: params[:email], subject: "Your Fantasy Draft sign-in code")
  end
end
