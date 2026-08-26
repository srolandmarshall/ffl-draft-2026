// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import { Turbo } from "@hotwired/turbo-rails"
import "controllers"

Turbo.StreamActions.refresh_frame = function () {
  const frame = document.getElementById(this.target)
  if (!frame) return

  const refreshUrl = frame.dataset.playerRefreshUrl

  if (refreshUrl && frame.getAttribute("src") !== refreshUrl) {
    frame.src = refreshUrl
  } else if (frame.hasAttribute("src")) {
    frame.reload()
  } else {
    frame.src = window.location.href
  }
}

Turbo.StreamActions.visit = function () {
  Turbo.visit(this.getAttribute("target"))
}

Turbo.StreamActions.draft_turn = function () {
  const room = document.getElementById(this.target)
  if (!room) return

  room.dispatchEvent(new CustomEvent("draft:turn", {
    detail: {
      teamId: this.getAttribute("team-id"),
      teamName: this.getAttribute("team-name"),
      round: this.getAttribute("round"),
      pick: this.getAttribute("pick")
    }
  }))
}

Turbo.StreamActions.draft_pick_announcement = function () {
  const ticker = document.getElementById(this.target)
  if (!ticker) return

  ticker.dispatchEvent(new CustomEvent("draft:pick-announcement", {
    detail: {
      kind: this.getAttribute("kind"),
      message: this.getAttribute("message"),
      teamName: this.getAttribute("team-name"),
      playerName: this.getAttribute("player-name"),
      logoUrl: this.getAttribute("logo-url"),
      round: this.getAttribute("round"),
      pick: this.getAttribute("pick"),
      overall: this.getAttribute("overall")
    }
  }))
}
