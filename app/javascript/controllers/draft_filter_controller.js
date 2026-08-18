import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "position", "team", "teamSummary", "row", "empty", "count", "all"]
  static values = { delay: { type: Number, default: 250 } }

  connect() {
    this.resizeHandler = () => this.filter()
    window.addEventListener("resize", this.resizeHandler)
    this.filter()
  }

  disconnect() {
    clearTimeout(this.searchTimer)
    window.removeEventListener("resize", this.resizeHandler)
  }

  search() {
    clearTimeout(this.searchTimer)
    this.searchTimer = setTimeout(() => this.filter(), this.delayValue)
  }

  togglePosition() {
    this.filter()
  }

  toggleTeam() {
    this.filter()
  }

  clearPositions() {
    this.positionTargets.forEach((input) => { input.checked = false })
    this.filter()
  }

  filter() {
    const query = this.queryTarget.value.trim().toLowerCase()
    const positions = new Set(this.positionTargets.filter((input) => input.checked).map((input) => input.value))
    const teams = new Set(this.teamTargets.filter((input) => input.checked).map((input) => input.value))
    this.allTarget.setAttribute("aria-pressed", positions.size === 0)
    if (this.hasTeamSummaryTarget) {
      this.teamSummaryTarget.textContent = teams.size === 0 ? "All teams" : `${teams.size} team${teams.size === 1 ? "" : "s"}`
    }
    const activeLayout = window.matchMedia("(min-width: 768px)").matches ? "desktop" : "mobile"
    let visible = 0

    this.rowTargets.forEach((row) => {
      const matchesQuery = !query || row.dataset.playerName.includes(query)
      const matchesPosition = positions.size === 0 || positions.has(row.dataset.playerPosition)
      const matchesTeam = teams.size === 0 || teams.has(row.dataset.playerTeam)
      const matches = matchesQuery && matchesPosition && matchesTeam
      row.classList.toggle("hidden", !matches)
      if (matches && row.dataset.layout === activeLayout) visible += 1
    })

    this.countTarget.textContent = visible
    this.emptyTargets.forEach((empty) => empty.classList.toggle("hidden", visible !== 0))
  }
}
