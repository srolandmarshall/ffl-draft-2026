# frozen_string_literal: true

class Components::Sessions::OauthConsent < Components::Base
  def initialize(oauth_request:)
    @oauth_request = oauth_request
  end

  def view_template
    content_for(:title, "Authorize fantasy access")
    div(class: "mx-auto max-w-2xl rounded-xl border border-white/10 bg-slate-900 p-7") do
      p(class: "text-sm font-bold text-lime-400") { "Fantasy Draft MCP" }
      h1(class: "mt-2 text-2xl font-bold") { "Authorize read-only access?" }
      p(class: "mt-3 text-sm text-slate-300") do
        plain "#{oauth_request.fetch(:client_name)} wants to read the fantasy leagues and teams available to your account."
      end
      p(class: "mt-3 rounded-lg bg-slate-950 p-3 text-sm text-slate-400") do
        strong(class: "text-slate-200") { "Permission: " }
        plain oauth_request.fetch(:scope)
      end
      consent_form
    end
  end

  private

  attr_reader :oauth_request

  def consent_form
    form_with(url: oauth_authorize_path, method: :post, class: "mt-6 flex flex-wrap gap-3") do |form|
      form.hidden_field(:oauth_request, value: oauth_request.fetch(:token))
      button(
        type: "submit",
        name: "decision",
        value: "approve",
        class: "cursor-pointer rounded-lg bg-lime-400 px-5 py-2.5 font-semibold text-slate-950 hover:bg-lime-300"
      ) { "Authorize" }
      button(
        type: "submit",
        name: "decision",
        value: "deny",
        class: "cursor-pointer rounded-lg border border-white/15 px-5 py-2.5 font-semibold hover:bg-white/5"
      ) { "Deny" }
    end
  end
end
