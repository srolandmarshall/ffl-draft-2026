// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import { Turbo } from "@hotwired/turbo-rails"
import "controllers"

Turbo.StreamActions.refresh_frame = function () {
  const frame = document.getElementById(this.target)
  if (!frame) return

  if (frame.hasAttribute("src")) {
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
