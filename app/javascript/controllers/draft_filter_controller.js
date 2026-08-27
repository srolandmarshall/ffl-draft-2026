import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "position", "team", "teamCount"]
  static values = { delay: { type: Number, default: 500 } }

  disconnect() {
    clearTimeout(this.submitTimer)
  }

  scheduleSubmit() {
    clearTimeout(this.submitTimer)
    this.submitTimer = setTimeout(() => this.submit(), this.delayValue)
  }

  submit() {
    this.element.requestSubmit()
  }

  clearPositions() {
    this.positionTargets.forEach((input) => { input.checked = false })
    this.scheduleSubmit()
  }

  updateTeamSelection() {
    const selectedTeams = this.teamTargets.filter((input) => input.checked).length
    this.teamCountTarget.textContent = selectedTeams === 0 ? "All teams" : `${selectedTeams} selected`
  }

  clearTeams() {
    this.teamTargets.forEach((input) => { input.checked = false })
    this.updateTeamSelection()
    this.scheduleSubmit()
  }

  clearFilters() {
    this.queryTarget.value = ""
    this.positionTargets.forEach((input) => { input.checked = false })
    this.teamTargets.forEach((input) => { input.checked = false })
    this.updateTeamSelection()
    this.scheduleSubmit()
  }
}
