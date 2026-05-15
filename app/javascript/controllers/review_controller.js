import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="review"
export default class extends Controller {
  static targets = ["answer", "showButton"]

  showAnswer() {
    if (!this.answerTarget.hidden) return

    this.answerTarget.hidden = false
    if (this.hasShowButtonTarget) this.showButtonTarget.hidden = true
  }

  handleKeydown(event) {
    if (event.target.matches("input, textarea, select")) return

    if (event.key === " " || event.key === "Enter") {
      event.preventDefault()
      this.showAnswer()
    }

    const button = this.element.querySelector(`[data-review-rating="${event.key}"]`)
    if (button) {
      button.click()
    }
  }
}
