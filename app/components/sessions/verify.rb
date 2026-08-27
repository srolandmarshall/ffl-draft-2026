# frozen_string_literal: true

class Components::Sessions::Verify < Components::Base
  def initialize(login_code_sent_at:)
    @login_code_sent_at = login_code_sent_at
  end

  def view_template
    content_for(:title, "Verify sign in")
    div(class: "mx-auto max-w-2xl rounded-xl border border-white/10 bg-slate-900 p-7") do
      p(class: "text-sm font-bold text-lime-400") { "Fantasy Draft" }
      h1(class: "mt-2 text-2xl font-bold") { "Enter your sign-in code" }
      p(class: "mt-2 text-sm text-slate-400") { "Check your email for the six-digit code. It expires in 10 minutes." }
      form_with(url: verify_session_path, html: { id: "verify-login-code" }, class: "mt-6 space-y-4") do |form|
        div do
          form.label(:code, "Sign-in code", class: "mb-2 block text-sm font-bold")
          form.text_field(:code, required: true, autofocus: true, autocomplete: "one-time-code", inputmode: "numeric", maxlength: 6, pattern: "[0-9]{6}", class: "w-full rounded-lg border border-white/15 bg-slate-950 px-3 py-2.5 tracking-[0.35em]", placeholder: "123456")
        end
      end
      action_buttons
    end
  end

  private

  def action_buttons
    available_at = @login_code_sent_at + User::LOGIN_CODE_RESEND_DELAY
    remaining_seconds = [ (available_at - Time.current).ceil, 0 ].max

    div(class: "mt-4 flex items-center justify-between gap-4", data: { controller: "login-code-resend", login_code_resend_available_at_value: available_at.iso8601 }) do
      form_with(url: resend_login_code_session_path) do |form|
        form.submit(
          resend_label(remaining_seconds),
          disabled: remaining_seconds.positive?,
          class: "cursor-pointer rounded-lg border border-lime-400/60 px-5 py-2.5 text-sm font-semibold text-lime-400 hover:border-lime-300 hover:text-lime-300 disabled:cursor-not-allowed disabled:border-slate-700 disabled:text-slate-500",
          data: { login_code_resend_target: "submit" }
        )
      end
      button(type: "submit", form: "verify-login-code", class: "cursor-pointer rounded-lg bg-lime-400 px-5 py-2.5 font-semibold text-slate-950 hover:bg-lime-300") { "Verify and sign in" }
    end
  end

  def resend_label(seconds)
    seconds.positive? ? "Resend code (#{format_duration(seconds)})" : "Resend code"
  end

  def format_duration(seconds)
    Kernel.format("%d:%02d", seconds / 60, seconds % 60)
  end
end
