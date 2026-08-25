# frozen_string_literal: true

class Components::Admin::Users::Index < Components::Base
  def initialize(users:)
    @users = users
  end

  def view_template
    content_for(:title, "Users")
    div(class: "mb-7") do
      p(class: "text-sm font-bold text-lime-400") { "Commissioner tools" }
      h1(class: "mt-1 text-2xl font-bold") { "Users" }
      p(class: "mt-2 text-sm text-slate-400") { "Team emails appear here after they are assigned. Promote trusted people to commissioner when they need setup access." }
    end
    div(class: "overflow-hidden rounded-xl border border-white/10 bg-slate-900") { @users.each { |user| user_row(user) } }
  end

  private

  def user_row(user)
    div(class: "flex flex-col gap-3 border-b border-white/10 px-5 py-4 last:border-0 sm:flex-row sm:items-center sm:justify-between") do
      div do
        p(class: "font-semibold") { user.email }
        p(class: "mt-1 text-xs text-slate-500") { user.teams.any? ? user.teams.map(&:name).join(", ") : "No team assigned" }
      end
      form_with(model: [ :admin, user ], class: "flex items-center gap-2") do |form|
        form.select(:role, User.roles.keys.map { |role| [ role.titleize, role ] }, {}, class: "rounded-lg border border-white/15 bg-slate-950 px-3 py-2 text-sm")
        form.submit("Save", class: "cursor-pointer rounded-lg bg-white/10 px-3 py-2 text-sm font-bold hover:bg-white/15")
      end
    end
  end
end
