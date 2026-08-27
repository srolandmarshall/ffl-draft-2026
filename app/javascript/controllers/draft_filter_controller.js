import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "position", "positionCount", "positionMenu", "team", "teamCount", "teamMenu"]
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
    this.updatePositionSelection()
    this.scheduleSelection()
  }

  syncPositionSelection(event) {
    const { value, checked } = event.target
    this.positionTargets.forEach((input) => {
      if (input.value === value) input.checked = checked
    })
    this.updatePositionSelection()
    this.scheduleSelection()
  }

  updatePositionSelection() {
    if (!this.hasPositionCountTarget) return

    const selectedPositions = new Set(this.positionTargets.filter((input) => input.checked).map((input) => input.value))
    this.positionCountTarget.textContent = selectedPositions.size === 0 ? "All positions" : `${selectedPositions.size} selected`
  }

  closePositionMenu() {
    this.positionMenuTarget.removeAttribute("open")
  }

  updateTeamSelection() {
    if (!this.hasTeamCountTarget) return

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
    this.updatePositionSelection()
    this.updateTeamSelection()
    this.scheduleSelection()
  }
}
