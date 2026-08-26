import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="draft-pick-ticker"
export default class extends Controller {
  static targets = ["ticker", "announcement", "message", "logo", "details"]

  connect() {
    this.queue = []
    this.displaying = false
  }

  disconnect() {
    window.clearTimeout(this.displayTimeout)
  }

  enqueue(event) {
    this.queue.push(event.detail)
    this.showNext()
  }

  showNext() {
    if (this.displaying || this.queue.length === 0) return

    this.displaying = true
    const announcement = this.queue.shift()
    const pick = announcement.kind === "pick"

    this.messageTarget.textContent = pick
      ? `${announcement.teamName} SELECTS ${announcement.playerName}`
      : announcement.message
    this.detailsTarget.textContent = pick ? `(ROUND ${announcement.round}, PICK ${announcement.pick}, ${announcement.overall} OVERALL)` : ""
    this.detailsTarget.classList.toggle("hidden", !pick)
    this.logoTarget.classList.toggle("hidden", !pick)
    if (pick) this.logoTarget.src = announcement.logoUrl
    else this.logoTarget.removeAttribute("src")
    this.tickerTarget.hidden = false

    this.announcementTarget.classList.remove("draft-pick-ticker-scroll-in", "draft-pick-ticker-scroll-out")
    if (!window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      void this.announcementTarget.offsetWidth
      this.announcementTarget.classList.add("draft-pick-ticker-scroll-in")
    }

    this.displayTimeout = window.setTimeout(() => {
      this.announcementTarget.classList.remove("draft-pick-ticker-scroll-in")
      if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
        this.finishAnnouncement()
      } else {
        void this.announcementTarget.offsetWidth
        this.announcementTarget.classList.add("draft-pick-ticker-scroll-out")
        this.displayTimeout = window.setTimeout(() => this.finishAnnouncement(), 650)
      }
    }, 4000)
  }

  finishAnnouncement() {
    this.tickerTarget.hidden = true
    this.announcementTarget.classList.remove("draft-pick-ticker-scroll-in", "draft-pick-ticker-scroll-out")
    this.displaying = false
    this.showNext()
  }
}
