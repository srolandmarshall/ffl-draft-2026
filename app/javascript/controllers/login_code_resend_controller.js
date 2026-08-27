import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submit", "status"]
  static values = { availableAt: String }

  connect() {
    this.tick()
    this.interval = window.setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    window.clearInterval(this.interval)
  }

  tick() {
    const remainingSeconds = Math.max(0, Math.ceil((Date.parse(this.availableAtValue) - Date.now()) / 1000))

    this.submitTarget.disabled = remainingSeconds > 0
    this.statusTarget.textContent = remainingSeconds > 0
      ? `You can request another code in ${this.formatDuration(remainingSeconds)}.`
      : "Didn't receive it? You can request another code."

    if (remainingSeconds === 0) window.clearInterval(this.interval)
  }

  formatDuration(seconds) {
    return `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, "0")}`
  }
}
