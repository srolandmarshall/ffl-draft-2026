# frozen_string_literal: true

class Components::Navigation < Components::Base
  def initialize(current_user:, team: nil)
    @current_user = current_user
    @team = team
  end

  def view_template
    header(class: "border-b border-white/10 bg-slate-950") do
      nav(class: "mx-auto flex max-w-7xl items-center justify-between px-3 py-3 sm:px-5 sm:py-4") do
        a(href: root_path, class: "font-semibold text-slate-200 hover:text-white") { "Draft home" }
        div(class: "flex items-center gap-5 text-sm font-semibold text-slate-300") do
          a(href: admin_root_path, class: "hover:text-white") { "League admin" } if @current_user&.commissioner?
          if @current_user
            span(class: "hidden text-slate-400 sm:inline", data: { user_identity: true }) { user_identity }
            raw button_to("Sign out", session_path, method: :delete, class: "cursor-pointer hover:text-white")
          else
            a(href: new_session_path, class: "hover:text-white") { "Sign in" }
          end
        end
      end
    end
  end

  private

  def user_identity
    navigation_team&.name || (@current_user.commissioner? ? "Commissioner" : "Team member")
  end

  def navigation_team
    @navigation_team ||= @team || @current_user.teams.joins(:league).order(leagues: { season: :desc, id: :desc }, draft_order: :asc, id: :asc).first
  end
end
