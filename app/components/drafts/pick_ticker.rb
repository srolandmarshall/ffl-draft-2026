# frozen_string_literal: true

class Components::Drafts::PickTicker < Components::Base
  def initialize(draft:)
    @draft = draft
  end

  def view_template
    div(class: "relative z-40 h-0") do
      div(
        id: dom_id,
        class: "draft-pick-ticker fixed inset-x-3 top-3 z-50 mx-auto max-w-7xl overflow-hidden rounded-xl border border-lime-300/40 bg-slate-900 shadow-lg shadow-black/20 sm:inset-x-5",
        hidden: true,
        role: "status",
        aria: { live: "polite", atomic: "true" },
        data: {
          controller: "draft-pick-ticker",
          action: "draft:pick-announcement->draft-pick-ticker#enqueue",
          draft_pick_ticker_target: "ticker"
        }
      ) do
        div(class: "flex min-w-max items-center gap-3 px-4 py-3 sm:px-5", data: { draft_pick_ticker_target: "announcement" }) do
          p(class: "whitespace-nowrap text-lg font-black tracking-wide text-white sm:text-2xl", data: { draft_pick_ticker_target: "message" })
          img(class: "hidden size-8 shrink-0 rounded border border-white/15 bg-slate-400/50 p-0.5 object-contain", alt: "", data: { draft_pick_ticker_target: "logo" })
          p(class: "hidden whitespace-nowrap text-base font-black tracking-wide text-slate-300 sm:text-xl", data: { draft_pick_ticker_target: "details" })
        end
      end
    end
  end

  private

  def dom_id = "draft-#{@draft.public_id}-pick-ticker"
end
