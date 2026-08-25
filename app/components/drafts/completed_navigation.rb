# frozen_string_literal: true

class Components::Drafts::CompletedNavigation < Components::Base
  def initialize(draft:, view: nil)
    @draft = draft
    @view = view
  end

  def view_template
    nav(class: "mb-4 grid grid-cols-2 overflow-hidden rounded-xl border border-white/15 bg-slate-900 shadow-xl shadow-black/20", aria: { label: "Post-draft view" }) do
      navigation_link("Draft Board", "Review every selection", draft_path(@draft.public_id), active: @view.blank? || @view == "board")
      navigation_link("Draft Facts", "Relive the night's superlatives", draft_path(@draft.public_id, view: "facts"), active: @view == "facts", facts: true)
    end
  end

  private

  def navigation_link(label, description, href, active:, facts: false)
    active_classes = facts ? "bg-fuchsia-300 text-slate-950" : "bg-white text-slate-950"
    inactive_classes = facts ? "text-fuchsia-300 hover:bg-white/5" : "text-slate-400 hover:bg-white/5 hover:text-white"
    a(href:, class: "group px-4 py-4 transition sm:px-5 #{'border-l border-white/15' if facts} #{active ? active_classes : inactive_classes}", aria: { current: ("page" if active) }) do
      span(class: "block text-base font-black sm:text-lg") { label }
      span(class: "mt-0.5 block text-[.65rem] font-semibold sm:text-xs") { description }
    end
  end
end
