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
    clearTimeout(this.removeTimer)
  }

  close() {
    this.element.classList.add("is-leaving")

    const remove = () => {
      if (this.element.isConnected) this.element.remove()
    }

    this.element.addEventListener("animationend", remove, { once: true })

    // Fallback: reduced-motion or a missing animation never fires
    // animationend, which otherwise leaves the flash on screen forever.
    this.removeTimer = setTimeout(remove, 1000)
  }
}