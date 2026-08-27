Resend.api_key = -> { ENV.fetch("RESEND_API_KEY") }
ENV.fetch("RESEND_FROM_EMAIL") if Rails.env.production?
