import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { messages: Array }

  submit(event) {
    if (this.confirmed) return

    event.preventDefault()

    for (const message of this.messagesValue) {
      if (!window.confirm(message)) return
    }

    this.confirmed = true
    this.element.requestSubmit()
  }
}
