# frozen_string_literal: true

class Components::Admin::EspnConnection < Components::Base
  def initialize(league:)
    @league = league
  end

  def view_template
    div(class: "mx-auto max-w-xl") do
      p(class: "text-sm font-bold text-lime-400") { "ESPN integration" }
      h1(class: "text-2xl font-semibold") { "Connect private ESPN league" }
      p(class: "mt-2 text-sm text-slate-400") { "#{@league.name} is associated with ESPN league ##{@league.espn_league_id} for #{@league.season}." }
      div(class: "mt-6 rounded-lg border border-white/10 bg-slate-900 p-6") do
        instructions
        connection_form
      end
    end
  end

  private

  def instructions
    div(class: "mb-6 rounded-lg border border-white/10 bg-slate-950 p-4 text-sm text-slate-300") do
      p(class: "font-bold text-white") { "Get the two cookie values from ESPN" }
      ol(class: "mt-2 list-decimal space-y-1 pl-5 text-xs leading-relaxed text-slate-400") do
        li do
          a(href: "https://fantasy.espn.com/football/", target: "_blank", rel: "noopener", class: "font-bold text-lime-400 hover:text-lime-300") { "Sign in to ESPN Fantasy" }
          plain "."
        end
        li { "Open your browser's developer tools, then Application/Storage → Cookies → espn.com." }
        li do
          plain "Copy the values named "
          code { "espn_s2" }
          plain " and "
          code { "SWID" }
          plain " below."
        end
      end
    end
  end

  def connection_form
    form_with(url: admin_league_espn_connection_path(@league), class: "space-y-5") do |form|
      password_field(form, :espn_s2, "espn_s2 cookie")
      password_field(form, :swid, "SWID cookie", placeholder: "{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}")
      p(class: "text-xs leading-relaxed text-slate-500") { "These values are verified with ESPN and retained only in this browser's encrypted Rails session. They are never saved to the database, and signing out removes them." }
      div(class: "flex gap-3") do
        form.submit("Connect and sync league", class: "cursor-pointer rounded-lg bg-lime-400 px-4 py-2 font-bold text-slate-950 hover:bg-lime-300")
        a(href: admin_league_path(@league), class: "rounded-lg border border-white/15 px-4 py-2 font-bold") { "Cancel" }
      end
    end
  end

  def password_field(form, attribute, label, **options)
    div do
      form.label(attribute, label, class: "mb-2 block text-sm font-bold")
      form.password_field(attribute, required: true, autocomplete: "off", **options, class: "w-full rounded-lg border border-white/15 bg-slate-950 px-3 py-2.5")
    end
  end
end
