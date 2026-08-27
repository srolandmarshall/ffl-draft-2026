class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("RESEND_FROM_EMAIL", "from@example.com")
  layout "mailer"
end
