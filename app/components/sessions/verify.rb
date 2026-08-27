# frozen_string_literal: true

class Components::Sessions::Verify < Components::Base
  def view_template
    content_for(:title, "Verify sign in")
    div(class: "mx-auto max-w-2xl rounded-xl border border-white/10 bg-slate-900 p-7") do
      p(class: "text-sm font-bold text-lime-400") { "Fantasy Draft" }
      h1(class: "mt-2 text-2xl font-bold") { "Enter your sign-in code" }
      p(class: "mt-2 text-sm text-slate-400") { "Check your email for the six-digit code. It expires in 10 minutes." }
      form_with(url: verify_session_path, class: "mt-6 space-y-4") do |form|
        div do
          form.label(:code, "Sign-in code", class: "mb-2 block text-sm font-bold")
          form.text_field(:code, required: true, autofocus: true, autocomplete: "one-time-code", inputmode: "numeric", maxlength: 6, pattern: "[0-9]{6}", class: "w-full rounded-lg border border-white/15 bg-slate-950 px-3 py-2.5 tracking-[0.35em]", placeholder: "123456")
        end
        form.submit("Verify and sign in", class: "cursor-pointer rounded-lg bg-lime-400 px-5 py-2.5 font-semibold text-slate-950 hover:bg-lime-300")
      end
    end
  end
end
