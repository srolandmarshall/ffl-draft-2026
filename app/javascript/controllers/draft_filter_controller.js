import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "position"]
  static values = { delay: { type: Number, default: 400 } }

  disconnect() {
    clearTimeout(this.searchTimer)
  }

  search() {
    clearTimeout(this.searchTimer)
    this.searchTimer = setTimeout(() => this.submit(), this.delayValue)
  }

  submit() {
    this.element.requestSubmit()
  }

  clearPositions() {
    this.positionTargets.forEach((input) => { input.checked = false })
    this.submit()
  }
}
