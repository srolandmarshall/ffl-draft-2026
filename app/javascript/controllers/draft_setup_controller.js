import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["count", "team"]

  connect() {
    this.update()
  }

  update() {
    const count = Number(this.countTarget.value)

    this.teamTargets.forEach((team) => {
      const active = Number(team.dataset.index) < count
      team.classList.toggle("hidden", !active)
      team.querySelectorAll("[data-required-for-team]").forEach((input) => {
        input.required = active
      })
    })
  }
}
