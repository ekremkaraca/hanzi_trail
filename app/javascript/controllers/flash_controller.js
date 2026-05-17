import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    timeout: { type: Number, default: 4000 },
  }

  connect() {
    this.dismissTimer = setTimeout(() => {
      this.close()
    }, this.timeoutValue)
  }

  disconnect() {
    clearTimeout(this.dismissTimer)
  }

  close() {
    this.element.classList.add("is-leaving")

    this.element.addEventListener(
      "animationend",
      () => {
        this.element.remove()
      },
      { once: true },
    )
  }
}