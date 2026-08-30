import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "position"]

  dragStart(event) {
    this.draggedItem = event.currentTarget
    event.dataTransfer.effectAllowed = "move"
    event.currentTarget.classList.add("opacity-50")
  }

  dragOver(event) {
    event.preventDefault()
    const target = event.currentTarget
    if (!this.draggedItem || target === this.draggedItem) return

    const rectangle = target.getBoundingClientRect()
    const insertAfter = event.clientY > rectangle.top + rectangle.height / 2
    target.parentNode.insertBefore(this.draggedItem, insertAfter ? target.nextSibling : target)
  }

  drop(event) {
    event.preventDefault()
    this.updatePositions()
  }

  dragEnd(event) {
    event.currentTarget.classList.remove("opacity-50")
    this.draggedItem = null
  }

  updatePositions() {
    this.itemTargets.forEach((item, index) => {
      this.positionTargets[index].textContent = `Pick ${index + 1}`
      item.dataset.index = index
      item.querySelectorAll("[name]").forEach((field) => {
        field.name = field.name.replace(/(draft\[team_slots\]\[)\d+(\])/, `$1${index}$2`)
      })
    })

    this.dispatch("changed")
  }
}
