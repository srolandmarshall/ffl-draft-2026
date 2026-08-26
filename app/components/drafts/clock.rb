# frozen_string_literal: true

class Components::Drafts::Clock < Components::Base
  def initialize(draft:, selected_team:, picks_until_selected_team:, picks:, current_pick_elapsed_seconds:, current_user:)
    @draft = draft
    @selected_team = selected_team
    @picks_until_selected_team = picks_until_selected_team
    @picks = picks
    @current_pick_elapsed_seconds = current_pick_elapsed_seconds
    @current_user = current_user
  end

  def view_template
    section(class: "w-full overflow-hidden rounded-xl border border-white/15 bg-slate-900/95 shadow-lg shadow-black/30 backdrop-blur") do
      div(class: "p-3 sm:p-4") do
        div(class: "flex min-w-0 items-start justify-between gap-3 sm:items-center sm:gap-6") do
          clock_identity
          clock_timer if @draft.live?
        end
        commissioner_broadcast_form if @draft.live? && @current_user&.commissioner?
      end
    end
  end

  private

  def clock_identity
    div(class: "min-w-0") do
      if @draft.live?
        p(class: "text-[.65rem] font-bold uppercase tracking-[.2em] text-slate-400") { "On the clock" }
        p(class: "mt-0.5 break-words text-xl font-black text-lime-400 sm:text-2xl", data: { draft_pick_target: "currentTeam" }) { @draft.current_team&.name }
        p(class: "mt-0.5 text-[.65rem] font-semibold uppercase tracking-[.2em] text-slate-400", data: { draft_pick_target: "turnPosition" }) { "Round #{@draft.current_round}, Pick #{@draft.next_overall_number}" }
        last_pick = @draft.current_team && @picks.reverse_each.find { |pick| pick.team_id == @draft.current_team.id }
        p(class: "mt-1 break-words text-[.65rem] font-semibold text-slate-500") do
          plain "Last pick: "
          span(class: "text-slate-300") { last_pick.player.name }
          plain " · R#{last_pick.round} · Pick #{last_pick.overall_number}"
        end if last_pick
        selected_team_status
        sound_control
      else
        p(class: "font-bold") { "Draft room is ready" }
        p(class: "text-xs text-slate-500") { waiting_message }
      end
    end
  end

  def selected_team_status
    return unless @selected_team

    ready = @picks_until_selected_team.to_i.zero?
    status = if @picks_until_selected_team.nil?
      "No picks remaining"
    elsif ready
      "You're up now"
    else
      "#{@picks_until_selected_team} #{@picks_until_selected_team == 1 ? 'pick' : 'picks'} away"
    end
    p(class: "mt-0.5 break-words text-xs font-bold #{ready ? 'text-lime-400' : 'text-slate-400'}") do
      span(class: "text-slate-300") { "#{@selected_team.name}:" }
      plain " #{status}"
    end
  end

  def waiting_message
    return "Waiting for the commissioner to start." unless @draft.scheduled_start_at

    "Starts automatically #{@draft.scheduled_start_at.in_time_zone.strftime('%A, %B %-d at %-I:%M %p %Z')}."
  end

  def sound_control
    return if @selected_team.nil? || @current_user&.commissioner?

    button(
      type: "button",
      class: "mt-2 cursor-pointer rounded border border-white/15 px-2 py-1 text-[.6rem] font-bold text-slate-400 transition hover:border-white/40 hover:text-white",
      aria: { pressed: "true", label: "Toggle your-turn sound" },
      data: { draft_alert_target: "toggle", action: "draft-alert#toggleSound" }
    ) { "Sound on" }
  end

  def clock_timer
    div(class: "shrink-0 text-right", data: { controller: "pick-timer", action: "draft:timer-reset->pick-timer#reset", pick_timer_elapsed_value: @current_pick_elapsed_seconds.to_i.to_s, pick_timer_paused_value: @draft.pick_timer_paused?.to_s }) do
      div(class: "flex justify-end") { span(class: "rounded bg-white/10 px-1.5 py-0.5 text-[.5rem] font-bold uppercase text-slate-300") { "Paused" } } if @draft.pick_timer_paused?
      p(class: "font-mono text-xl font-bold tabular-nums text-slate-100", data: { pick_timer_target: "elapsed" }) { "0:00" }
      commissioner_controls if @current_user&.commissioner?
    end
  end

  def commissioner_controls
    div(class: "mt-1 flex justify-end gap-2") do
      raw button_to(@draft.pick_timer_paused? ? "Resume" : "Pause", draft_pick_timer_path(@draft.public_id), method: :patch, params: { state: @draft.pick_timer_paused? ? "resume" : "pause" }, class: "cursor-pointer text-[.6rem] font-bold text-slate-400 underline hover:text-white")
      last_pick = @picks.last
      raw button_to("Undo last", draft_pick_path(@draft.public_id, last_pick), method: :delete, class: "cursor-pointer text-[.6rem] font-bold text-red-200 underline hover:text-white", form: { data: { turbo_confirm: "Undo #{last_pick.player.name} as the latest pick? The clock will pause." } }) if last_pick
    end
  end

  def commissioner_broadcast_form
    form_with(
      url: broadcast_message_admin_league_draft_path(@draft.league, @draft),
      class: "mt-3 flex gap-2 border-t border-white/10 pt-3",
      data: {
        controller: "broadcast-cooldown",
        action: "submit->broadcast-cooldown#submit turbo:submit-end->broadcast-cooldown#complete",
        broadcast_cooldown_seconds_value: 5,
        turbo_frame: "_top"
      }
    ) do
      input(name: "message", required: true, maxlength: 280, placeholder: "Broadcast a message…", aria: { label: "Broadcast message" }, class: "min-w-0 flex-1 rounded border border-fuchsia-400/40 bg-slate-950 px-2 py-1.5 text-xs text-white placeholder:text-slate-500")
      input(type: "submit", value: "Broadcast", class: "cursor-pointer rounded border border-fuchsia-400/40 px-2 py-1.5 text-xs font-bold text-fuchsia-200 hover:bg-fuchsia-400/10 disabled:cursor-not-allowed disabled:opacity-40", data: { broadcast_cooldown_target: "submit" })
    end
  end
end
