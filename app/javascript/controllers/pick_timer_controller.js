import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["elapsed"]
  static values = { elapsed: Number, paused: Boolean }

  connect() {
    this.connectedAt = Date.now()
    this.tick()
    this.interval = window.setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    window.clearInterval(this.interval)
  }

  tick() {
    const runningFor = this.pausedValue ? 0 : Math.floor((Date.now() - this.connectedAt) / 1000)
    const seconds = this.elapsedValue + runningFor
    this.elapsedTarget.textContent = this.format(seconds)
    this.elapsedTarget.classList.remove("text-slate-100", "text-yellow-300", "text-red-400")
    this.elapsedTarget.classList.add(seconds >= 90 ? "text-red-400" : seconds >= 60 ? "text-yellow-300" : "text-slate-100")
  }

  format(seconds) {
    const minutes = Math.floor(seconds / 60)
    const remainingSeconds = seconds % 60
    const hours = Math.floor(minutes / 60)
    const remainingMinutes = minutes % 60

    return hours > 0
      ? `${hours}:${String(remainingMinutes).padStart(2, "0")}:${String(remainingSeconds).padStart(2, "0")}`
      : `${minutes}:${String(remainingSeconds).padStart(2, "0")}`
  }
}
