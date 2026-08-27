# frozen_string_literal: true

class Components::Sessions::New < Components::Base
  def view_template
    content_for(:title, "Sign in")
    div(class: "mx-auto max-w-2xl rounded-xl border border-white/10 bg-slate-900 p-7") do
      p(class: "text-sm font-bold text-lime-400") { "Fantasy Draft" }
      h1(class: "mt-2 text-2xl font-bold") { "Enter your email" }
      p(class: "mt-2 text-sm text-slate-400") { "Use the email your commissioner assigned to your team. We'll email you a one-time sign-in code." }
      sign_in_form
    end
  end

  private

  def sign_in_form
    form_with(url: session_path, class: "mt-6 space-y-4") do |form|
      div do
        form.label(:email, class: "mb-2 block text-sm font-bold")
        form.email_field(:email, required: true, autofocus: true, autocomplete: "email", class: "w-full rounded-lg border border-white/15 bg-slate-950 px-3 py-2.5", placeholder: "you@example.com")
      end
      form.submit("Continue", class: "cursor-pointer rounded-lg bg-lime-400 px-5 py-2.5 font-semibold text-slate-950 hover:bg-lime-300")
    end
  end
end
