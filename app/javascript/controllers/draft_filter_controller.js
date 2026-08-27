import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "position", "team", "teamCount"]

  applyFilters() {
    this.element.requestSubmit()
  }

  clearPositions() {
    this.positionTargets.forEach((input) => { input.checked = false })
  }

  updateTeamSelection() {
    const selectedTeams = this.teamTargets.filter((input) => input.checked).length
    this.teamCountTarget.textContent = selectedTeams === 0 ? "All teams" : `${selectedTeams} selected`
  }

  clearTeams() {
    this.teamTargets.forEach((input) => { input.checked = false })
    this.updateTeamSelection()
  }

  clearFilters() {
    this.queryTarget.value = ""
    this.clearPositions()
    this.clearTeams()
  }
}
