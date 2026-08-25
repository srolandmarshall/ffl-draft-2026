# frozen_string_literal: true

class Components::Drafts::Action < Components::Base
  def initialize(draft:, player:, can_make_pick:)
    @draft = draft
    @player = player
    @can_make_pick = can_make_pick
  end

  def view_template
    form(action: draft_picks_path(@draft.public_id), method: "post", class: "inline-flex justify-end") do
      input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
      input(type: "hidden", name: "player_id", value: @player.id)
      button(type: "button", disabled: !@can_make_pick, class: trigger_classes, data: { draft_pick_target: "trigger", action: "draft-pick#prepare" }) { "Draft" }
      span(class: "inline-flex items-center gap-1", hidden: true, data: { draft_pick_target: "confirmation" }) do
        button(type: "submit", class: "flex size-7 cursor-pointer items-center justify-center rounded border border-lime-300 bg-lime-400 text-base font-black leading-none text-slate-950 hover:bg-lime-300", title: "Confirm #{@player.name}", aria: { label: "Confirm drafting #{@player.name}" }, data: { draft_pick_target: "confirm" }) { "✓" }
        button(type: "button", class: "flex size-7 cursor-pointer items-center justify-center rounded border border-white/20 bg-white/5 text-base font-bold leading-none text-slate-300 hover:border-red-400 hover:text-red-300", title: "Cancel", aria: { label: "Cancel drafting #{@player.name}" }, data: { action: "draft-pick#cancel" }) { "×" }
      end
    end
  end

  private

  def trigger_classes
    "h-7 w-[3.75rem] rounded-lg text-xs font-semibold enabled:cursor-pointer enabled:bg-lime-400 enabled:text-slate-950 enabled:hover:bg-lime-300 disabled:cursor-not-allowed disabled:bg-white/5 disabled:text-slate-600"
  end
end
