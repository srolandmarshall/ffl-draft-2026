import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "confirmation", "confirm", "currentTeam", "turnPosition"]
  static values = { selectedTeamId: Number, commissioner: Boolean }

  prepare(event) {
    const form = event.currentTarget.form
    const confirmation = form.querySelector("[data-draft-pick-target='confirmation']")

    event.currentTarget.classList.add("hidden")
    confirmation.hidden = false
    confirmation.querySelector("[data-draft-pick-target='confirm']").focus()
  }

  cancel(event) {
    const form = event.currentTarget.form
    const trigger = form.querySelector("[data-draft-pick-target='trigger']")

    event.currentTarget.closest("[data-draft-pick-target='confirmation']").hidden = true
    trigger.classList.remove("hidden")
    trigger.focus()
  }

  turnChanged(event) {
    const currentTeamId = Number(event.detail.teamId)
    const canMakePick = this.commissionerValue || (this.hasSelectedTeamIdValue && this.selectedTeamIdValue === currentTeamId)

    if (this.hasCurrentTeamTarget && event.detail.teamName) this.currentTeamTarget.textContent = event.detail.teamName
    if (this.hasTurnPositionTarget) this.turnPositionTarget.textContent = `Round ${event.detail.round}, Pick ${event.detail.pick}`
    this.triggerTargets.forEach((trigger) => {
      trigger.disabled = !canMakePick
      trigger.classList.remove("hidden")
    })
    this.confirmationTargets.forEach((confirmation) => { confirmation.hidden = true })
    this.element.querySelector("[data-controller~='pick-timer']")?.dispatchEvent(new CustomEvent("draft:timer-reset"))
  }
}
