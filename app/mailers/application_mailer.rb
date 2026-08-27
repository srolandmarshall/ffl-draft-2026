class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("RESEND_FROM_EMAIL", "Fantasy Draft <onboarding@resend.dev>")
  layout "mailer"
end
