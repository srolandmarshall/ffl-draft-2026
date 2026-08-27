import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "position", "team", "teamCount", "teamMenu"]
  static values = {
    searchDelay: { type: Number, default: 500 },
    selectionDelay: { type: Number, default: 250 }
  }

  disconnect() {
    clearTimeout(this.submitTimer)
  }

  scheduleSearch() {
    this.scheduleSubmit(this.searchDelayValue)
  }

  scheduleSelection() {
    this.scheduleSubmit(this.selectionDelayValue)
  }

  scheduleSubmit(delay) {
    clearTimeout(this.submitTimer)
    this.submitTimer = setTimeout(() => this.submit(), delay)
  }

  submit() {
    this.element.requestSubmit()
  }

  clearPositions() {
    this.positionTargets.forEach((input) => { input.checked = false })
    this.scheduleSelection()
  }

  updateTeamSelection() {
    return unless this.hasTeamCountTarget

    const selectedTeams = this.teamTargets.filter((input) => input.checked).length
    this.teamCountTarget.textContent = selectedTeams === 0 ? "All teams" : `${selectedTeams} selected`
  }

  clearTeams() {
    this.teamTargets.forEach((input) => { input.checked = false })
    this.updateTeamSelection()
    this.scheduleSelection()
  }

  closeTeamMenu() {
    this.teamMenuTarget.removeAttribute("open")
  }

  clearFilters() {
    this.queryTarget.value = ""
    this.positionTargets.forEach((input) => { input.checked = false })
    this.teamTargets.forEach((input) => { input.checked = false })
    this.updateTeamSelection()
    this.scheduleSelection()
  }
}
