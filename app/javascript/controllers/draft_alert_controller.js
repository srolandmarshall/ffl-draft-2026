import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle"]
  static values = {
    currentTeamId: Number,
    enabled: Boolean,
    selectedTeamId: Number,
    soundUrl: String
  }

  connect() {
    this.onClock = this.enabledValue && this.selectedTeamIdValue === this.currentTeamIdValue
    this.syncToggle()
  }

  disconnect() {
    this.stopAudio()
  }

  toggleTargetConnected(toggle) {
    this.syncToggle(toggle)
  }

  turnChanged(event) {
    const nextTeamId = Number(event.detail.teamId)
    const nextOnClock = this.enabledValue && this.selectedTeamIdValue === nextTeamId

    if (!this.onClock && nextOnClock && !this.muted()) this.play()

    this.onClock = nextOnClock
    this.currentTeamIdValue = nextTeamId
  }

  toggleSound() {
    const muted = !this.muted()
    this.storeMuted(muted)
    if (muted) this.stopAudio()
    this.syncToggle()
  }

  play() {
    this.stopAudio()
    this.audio = new Audio(this.soundUrlValue)
    this.audio.preload = "auto"
    this.audio.play()?.catch(() => {})
  }

  stopAudio() {
    if (!this.audio) return

    this.audio.pause()
    this.audio.currentTime = 0
    this.audio = null
  }

  muted() {
    if (this.sessionMuted !== undefined) return this.sessionMuted

    try {
      return window.localStorage.getItem(this.storageKey) === "true"
    } catch (_error) {
      return false
    }
  }

  storeMuted(muted) {
    this.sessionMuted = muted

    try {
      window.localStorage.setItem(this.storageKey, muted.toString())
    } catch (_error) {
      // Storage can be unavailable in private browsing; keep the preference for this page.
    }
  }

  syncToggle(toggle = null) {
    const muted = this.muted()
    const targets = toggle ? [toggle] : this.toggleTargets

    targets.forEach((element) => {
      element.setAttribute("aria-pressed", (!muted).toString())
      element.textContent = muted ? "Sound off" : "Sound on"
    })
  }

  get storageKey() {
    return "ffl-draft:pick-sound-muted"
  }
}
