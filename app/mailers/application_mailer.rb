class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("RESEND_FROM_EMAIL", "Fantasy Draft <draft@sammarshall.us>")
  layout "mailer"
end
