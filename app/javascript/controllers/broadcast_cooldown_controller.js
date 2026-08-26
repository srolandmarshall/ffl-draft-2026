import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="broadcast-cooldown"
export default class extends Controller {
  static targets = ["submit"]
  static values = { seconds: { type: Number, default: 5 } }

  connect() {
    this.originalLabel = this.submitTarget.value
  }

  disconnect() {
    window.clearInterval(this.interval)
  }

  submit(event) {
    if (this.submitTarget.disabled) {
      event.preventDefault()
      return
    }

    this.submitTarget.disabled = true
    this.submitTarget.value = "Sending…"
  }

  complete(event) {
    if (event.detail.success) this.startCooldown()
    else this.reset()
  }

  startCooldown() {
    this.remainingSeconds = this.secondsValue
    this.updateLabel()
    window.clearInterval(this.interval)
    this.interval = window.setInterval(() => {
      this.remainingSeconds -= 1
      if (this.remainingSeconds === 0) this.reset()
      else this.updateLabel()
    }, 1000)
  }

  updateLabel() {
    this.submitTarget.value = `${this.originalLabel} (${this.remainingSeconds}s)`
  }

  reset() {
    window.clearInterval(this.interval)
    this.submitTarget.disabled = false
    this.submitTarget.value = this.originalLabel
  }
}
