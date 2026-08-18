import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "confirmation", "confirm"]

  prepare() {
    this.triggerTarget.classList.add("hidden")
    this.confirmationTarget.hidden = false
    this.confirmTarget.focus()
  }

  cancel() {
    this.confirmationTarget.hidden = true
    this.triggerTarget.classList.remove("hidden")
    this.triggerTarget.focus()
  }
}
