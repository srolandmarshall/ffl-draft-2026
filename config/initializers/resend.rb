Resend.api_key = -> { ENV.fetch("RESEND_API_KEY") }
ENV.fetch("RESEND_FROM_EMAIL") if Rails.env.production? && ENV["SECRET_KEY_BASE_DUMMY"].blank?
