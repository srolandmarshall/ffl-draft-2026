# frozen_string_literal: true

class Components::Admin::Leagues::Show < Components::Base
  def initialize(page:)
    @page = page
    @league = page.league
  end

  def view_template
    header
    espn_panel
    espn_franchise_archive
    div(class: "grid gap-8 lg:grid-cols-2") do
      teams_frame
      drafts_frame
    end
  end

  private

  def header
    div(class: "mb-8 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between") do
      div do
        p(class: "text-sm font-bold text-lime-400") { "#{@league.season} season" }
        h1(class: "text-2xl font-semibold") { @league.name }
        p(class: "mt-2 text-sm text-slate-400") { "#{@league.roster_size} roster spots per team" }
      end
      a(href: edit_admin_league_path(@league), class: "rounded-lg border border-white/15 px-4 py-2 text-center font-bold hover:border-lime-400") { "Edit league" }
    end
  end

  def espn_panel
    section(class: "mb-8 rounded-lg border border-white/10 bg-slate-900 p-4") do
      div(class: "flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between") do
        espn_status
        espn_actions
      end
      espn_rules if @page.espn_settings
      p(class: "mt-3 border-t border-white/5 pt-3 text-[.65rem] text-slate-600") { "ESPN syncs team identities, rules, and draft history. It never changes the draft order saved here; new ESPN teams are appended." }
    end
  end

  def espn_status
    div do
      p(class: "text-xs font-bold uppercase tracking-wider text-slate-500") { "ESPN integration" }
      if @league.espn_league_id.present?
        p(class: "mt-1 font-semibold") { "League ##{@league.espn_league_id} · #{@league.season}" }
        status = @league.espn_synced_at ? "Last synced #{time_ago_in_words(@league.espn_synced_at)} ago · #{@page.espn_seasons.size} seasons of history" : "Connected; league data has not been synced yet."
        p(class: "mt-1 text-xs text-slate-500") { status }
      else
        p(class: "mt-1 text-sm text-slate-400") { "No ESPN league is associated with this league." }
      end
    end
  end

  def espn_actions
    unless @league.espn_league_id.present?
      a(href: edit_admin_league_path(@league), class: outline_action_classes) { "Connect ESPN league" }
      return
    end

    div(class: "flex flex-wrap gap-2") do
      button_to("Sync ESPN league", admin_league_espn_settings_sync_path(@league), class: "cursor-pointer rounded-lg bg-lime-400 px-4 py-2 text-sm font-bold text-slate-950 hover:bg-lime-300")
      button_to(
        "Repair ESPN history",
        admin_league_espn_franchise_backfill_path(@league),
        class: outline_action_classes,
        form: { data: { turbo_confirm: "Rebuild every ESPN franchise identity and reassign its archived draft picks?" } }
      ) if @page.espn_seasons.any?
      a(href: league_history_path(@league), class: "rounded-lg border border-blue-400/30 bg-blue-400/10 px-4 py-2 text-sm font-bold text-blue-200") { "View league history" } if @page.espn_seasons.any?
      if @page.espn_connected
        button_to("Disconnect ESPN", admin_league_espn_connection_path(@league), method: :delete, class: "cursor-pointer rounded-lg border border-white/15 px-4 py-2 text-sm font-bold")
      else
        a(href: new_admin_league_espn_connection_path(@league), class: outline_action_classes) { "Connect private league" }
      end
    end
  end

  def outline_action_classes = "rounded-lg border border-white/15 px-4 py-2 text-center text-sm font-bold hover:border-lime-400"

  def espn_franchise_archive
    return if @page.espn_franchises.empty?

    details(class: "mb-8 rounded-lg border border-white/10 bg-slate-900") do
      summary(class: "cursor-pointer px-4 py-3 text-sm font-bold text-slate-300") do
        plain "ESPN franchise archive"
        span(class: "ml-2 text-xs font-normal text-slate-500") { "#{@page.espn_franchises.size} teams across imported history" }
      end
      div(class: "border-t border-white/5") do
        @page.espn_franchises.each { |franchise| espn_franchise_row(franchise) }
      end
    end
  end

  def espn_franchise_row(franchise)
    seasons = franchise.team_seasons.map { |team_season| team_season.espn_season.season }.sort
    div(class: "flex flex-col gap-1 border-b border-white/5 px-4 py-3 last:border-0 sm:flex-row sm:items-center") do
      div(class: "min-w-0 flex-1") do
        p(class: "truncate text-sm font-semibold") { franchise.name }
        p(class: "text-xs text-slate-500") { espn_franchise_seasons(seasons) }
      end
      span(class: "text-xs font-semibold #{franchise.team ? 'text-lime-400' : 'text-slate-500'}") do
        franchise.team ? "Linked to #{franchise.team.name}" : "Historical only"
      end
    end
  end

  def espn_franchise_seasons(seasons)
    return "No imported seasons" if seasons.empty?
    return seasons.first.to_s if seasons.one?

    "#{seasons.first}–#{seasons.last} · #{seasons.size} seasons"
  end

  def espn_rules
    settings = @page.espn_settings
    div(class: "mt-4 grid gap-3 border-t border-white/5 pt-4 lg:grid-cols-3") do
      rule_summary("Roster", settings.lineup_rules.map { |position, count| "#{position} #{count}" }.join(" · "))
      rule_summary("League rules", settings.league_rules.first(4).map { |rule| "#{rule.label}: #{rule.value}" }.join(" · ").presence || "No additional rules returned")
      details do
        summary(class: "cursor-pointer text-[.65rem] font-bold uppercase tracking-wider text-lime-400") { "All scoring rules (#{settings.scoring_rules.size})" }
        div(class: "mt-2 grid grid-cols-2 gap-x-3 gap-y-1") do
          settings.scoring_rules.each do |rule|
            span(class: "text-[.65rem] text-slate-400") do
              plain "#{rule.label}: "
              strong(class: "text-slate-200") { rule.value }
            end
          end
        end
      end
    end
  end

  def rule_summary(label, value)
    div do
      p(class: "text-[.65rem] font-bold uppercase tracking-wider text-slate-500") { label }
      p(class: "mt-1 text-xs text-slate-300") { value }
    end
  end

  def teams_frame
    turbo_frame_tag("league-#{@league.id}-teams") do
      section do
        div(class: "mb-4 flex items-center justify-between") do
          div do
            h2(class: "text-xl font-semibold") { "Next draft order" }
            p(class: "mt-1 text-xs text-slate-500") { "Drag teams into place. Existing drafts keep their saved order." }
          end
          top_link("+ Add team", new_admin_league_team_path(@league))
        end
        team_order_form
        archived_teams_section
      end
    end
  end

  def team_order_form
    form_with(url: team_order_admin_league_path(@league), method: :patch, data: { controller: "team-order" }) do
      p(class: "mb-2 min-h-5 text-xs font-semibold text-lime-400", data: { team_order_target: "status" })
      div(class: "overflow-hidden rounded-lg border border-white/10 bg-slate-900") do
        @page.teams.each.with_index(1) { |team, position| team_row(team, position) }
        p(class: "p-7 text-center text-sm text-slate-500") { "Add teams before creating a draft." } if @page.teams.empty?
      end
      input(type: "submit", value: "Save order", class: "mt-3 cursor-pointer rounded-lg border border-white/15 px-3 py-2 text-xs font-bold hover:border-lime-400") if @page.teams.many?
    end
  end

  def team_row(team, position)
    div(draggable: "true", class: "flex cursor-move items-center gap-2 border-b border-white/5 px-3 py-2 last:border-0 hover:bg-white/[.03]", data: { team_id: team.id, team_order_target: "item", action: "dragstart->team-order#dragStart dragover->team-order#dragOver drop->team-order#drop dragend->team-order#dragEnd" }) do
      input(type: "hidden", name: "team_ids[]", value: team.id)
      span(class: "select-none text-slate-600", aria: { hidden: "true" }) { "⠿" }
      span(class: "w-6 shrink-0 text-center text-xs font-bold text-lime-400", data: { team_order_target: "position" }) { position }
      span(class: "w-12 shrink-0 text-xs font-semibold text-slate-500") { team.abbreviation }
      p(class: "min-w-0 flex-1 truncate text-sm font-semibold") do
        plain team.name
        span(class: "hidden font-normal text-slate-500 md:inline") { " · #{team.owner_name}" }
      end
      top_link("Edit", edit_admin_league_team_path(@league, team), class_name: "text-xs font-bold text-slate-400 hover:text-white")
      button_to("Archive", archive_admin_league_team_path(@league, team), method: :patch, class: "cursor-pointer text-xs font-bold text-slate-400 hover:text-red-300", form: { data: { turbo_confirm: "Archive #{team.name}? They'll drop out of the next draft's team list until restored." } })
    end
  end

  def archived_teams_section
    return if @page.archived_teams.empty?

    div(class: "mt-6 border-t border-white/5 pt-4") do
      h3(class: "text-xs font-bold uppercase tracking-wider text-slate-500") { "Archived teams" }
      div(class: "mt-2 overflow-hidden rounded-lg border border-white/10 bg-slate-900") do
        @page.archived_teams.each { |team| archived_team_row(team) }
      end
    end
  end

  def archived_team_row(team)
    div(class: "flex items-center gap-2 border-b border-white/5 px-3 py-2 text-slate-500 last:border-0") do
      span(class: "w-12 shrink-0 text-xs font-semibold") { team.abbreviation }
      p(class: "min-w-0 flex-1 truncate text-sm") { team.name }
      button_to("Restore", unarchive_admin_league_team_path(@league, team), method: :patch, class: "cursor-pointer text-xs font-bold text-lime-400 hover:text-lime-300")
    end
  end

  def drafts_frame
    turbo_frame_tag("league-#{@league.id}-drafts") do
      section do
        div(class: "mb-4 flex items-center justify-between") do
          h2(class: "text-xl font-semibold") { "Drafts" }
          top_link("+ Create draft", new_admin_league_draft_path(@league))
        end
        div(class: "space-y-3") do
          @page.drafts.each { |draft| draft_card(draft) }
          div(class: "rounded-lg border border-dashed border-white/15 p-7 text-center text-sm text-slate-500") { "No drafts yet." } if @page.drafts.empty?
        end
      end
    end
  end

  def draft_card(draft)
    div(class: "rounded-lg border border-white/10 bg-slate-900 p-5") do
      div(class: "flex items-start justify-between") do
        div do
          p(class: "font-semibold") { draft.name }
          p(class: "text-sm text-slate-400") { "#{draft.team_count} teams · #{draft.rounds} rounds · #{draft.ppr.to_f} PPR · #{draft.status}" }
          p(class: "mt-1 text-xs font-semibold text-blue-300") { "Scheduled for #{draft.scheduled_start_at.in_time_zone.strftime('%A, %B %-d at %-I:%M %p %Z')}" } if draft.setup? && draft.scheduled_start_at.present?
        end
        top_link(draft.complete? ? "View draft result →" : "Open room →", draft_path(draft.public_id, **({ view: "board" } if draft.complete?)), class_name: "text-sm font-bold text-lime-400")
      end
      draft_actions(draft)
    end
  end

  def draft_actions(draft)
    div(class: "mt-4 flex flex-wrap gap-3") do
      if draft.setup?
        button_to("Start draft", start_admin_league_draft_path(@league, draft), method: :patch, class: "cursor-pointer rounded-lg bg-lime-400 px-3 py-2 text-xs font-semibold text-slate-950", form: { data: { turbo_frame: "_top" } })
        top_link("Edit", edit_admin_league_draft_path(@league, draft), class_name: "rounded-lg border border-white/10 px-3 py-2 text-xs font-bold")
      else
        button_to("Restart draft", restart_admin_league_draft_path(@league, draft), method: :patch, class: "cursor-pointer rounded-lg border border-amber-400/40 px-3 py-2 text-xs font-bold text-amber-200 hover:bg-amber-400/10", form: { data: { turbo_confirm: "Restart #{draft.name}? This permanently removes all picks and starts it over.", turbo_frame: "_top" } })
      end
      auto_draft_button(draft) unless draft.complete?
      button_to("Delete draft", admin_league_draft_path(@league, draft), method: :delete, class: "cursor-pointer rounded-lg border border-red-400/40 px-3 py-2 text-xs font-bold text-red-200 hover:bg-red-400/10", form: { data: { turbo_confirm: "Delete #{draft.name}? This permanently removes the draft and all picks." } })
    end
  end

  def auto_draft_button(draft)
    return if Rails.env.production?

    button_to(
      "Auto-draft rest",
      auto_draft_admin_league_draft_path(@league, draft),
      method: :patch,
      class: "cursor-pointer rounded-lg border border-fuchsia-400/40 px-3 py-2 text-xs font-bold text-fuchsia-200 hover:bg-fuchsia-400/10",
      form: {
        data: {
          controller: "triple-confirm",
          triple_confirm_messages_value: auto_draft_confirm_messages(draft),
          action: "submit->triple-confirm#submit",
          turbo_frame: "_top"
        }
      }
    )
  end

  def auto_draft_confirm_messages(draft)
    [
      "Auto-draft the rest of #{draft.name}? This fills every remaining pick with computer-selected players.",
      "This cannot be undone except by restarting the draft, which wipes every pick made so far — including real picks from real teams. Continue?",
      "Final check: this is meant for testing end-of-draft states, not for finishing a real league's draft. Proceed?"
    ]
  end

  def top_link(label, href, class_name: "text-sm font-semibold text-lime-400 hover:text-lime-300")
    a(href:, class: class_name, data: { turbo_frame: "_top" }) { label }
  end
end
