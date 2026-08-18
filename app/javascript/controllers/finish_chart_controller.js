import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="finish-chart"
export default class extends Controller {
  static targets = ["series", "button", "teamName", "average", "best", "titles", "latest"]

  connect() {
    this.selectedKey = this.buttonTargets.find((button) => button.getAttribute("aria-pressed") === "true")?.dataset.key
    this.activate(this.selectedKey)
  }

  select(event) {
    this.selectedKey = event.currentTarget.dataset.key
    this.activate(this.selectedKey)
  }

  preview(event) {
    this.activate(event.currentTarget.dataset.key, true)
  }

  restore() {
    this.activate(this.selectedKey)
  }

  activate(key, preview = false) {
    const showAll = key === "all"

    this.seriesTargets.forEach((series) => {
      const active = showAll || series.dataset.key === key
      series.style.opacity = active ? (showAll ? "0.55" : "1") : "0.045"
      series.style.pointerEvents = active ? "auto" : "none"
      series.querySelector("polyline")?.setAttribute("stroke-width", active && !showAll ? "5" : "3")
      series.querySelectorAll("[data-finish-chart-label]").forEach((label) => {
        label.style.display = active ? "block" : "none"
      })
      if (active && !showAll) series.parentNode.appendChild(series)
    })

    if (!preview) {
      this.buttonTargets.forEach((button) => button.setAttribute("aria-pressed", button.dataset.key === key))
    }

    const button = this.buttonTargets.find((candidate) => candidate.dataset.key === key)
    if (!button) return

    this.teamNameTarget.textContent = button.dataset.name
    this.teamNameTarget.style.color = button.dataset.color || ""
    this.averageTarget.textContent = button.dataset.average
    this.bestTarget.textContent = button.dataset.best
    this.titlesTarget.textContent = button.dataset.titles
    this.latestTarget.textContent = button.dataset.latest
  }
}
