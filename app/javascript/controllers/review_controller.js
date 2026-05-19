import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="review"
export default class extends Controller {
  static targets = ["answer", "showButton"]

  showAnswer() {
    this.answerTarget.hidden = false
    this.showButtonTarget.hidden = true
    this.element.classList.add("is-answer-visible")
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
