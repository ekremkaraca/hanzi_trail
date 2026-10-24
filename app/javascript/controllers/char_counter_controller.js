import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field", "count"]
  static values = { limit: { type: Number, default: Infinity } }
  static classes = ["warning"]

  connect() {
    this.update()
    if (this.hasFieldTarget) {
      this.boundUpdate = this.update.bind(this)
      this.fieldTarget.addEventListener("input", this.boundUpdate)
    }
  }

  disconnect() {
    if (this.hasFieldTarget && this.boundUpdate) {
      this.fieldTarget.removeEventListener("input", this.boundUpdate)
    }
  }

  update() {
    if (!this.hasFieldTarget || !this.hasCountTarget) return
    const value = this.fieldTarget.value || ""
    this.count = value.length
    this.countTarget.textContent = String(this.count)

    const over = Number.isFinite(this.limitValue) && this.count >= this.limitValue
    this.element.classList.toggle(this.warningClass, over)
  }
}
