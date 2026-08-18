import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="history-tabs"
export default class extends Controller {
  static targets = ["tab", "panel"]

  select(event) {
    const year = event.currentTarget.dataset.year

    this.tabTargets.forEach((tab) => {
      const active = tab.dataset.year === year
      tab.setAttribute("aria-selected", active)
      tab.classList.toggle("border-lime-400", active)
      tab.classList.toggle("bg-lime-400", active)
      tab.classList.toggle("text-slate-950", active)
      tab.classList.toggle("border-white/10", !active)
      tab.classList.toggle("bg-slate-900", !active)
      tab.classList.toggle("text-slate-400", !active)
    })

    this.panelTargets.forEach((panel) => {
      panel.hidden = panel.dataset.year !== year
    })
  }
}
