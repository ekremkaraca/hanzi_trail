import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="review"
export default class extends Controller {
  static targets = ["answer", "showButton"]

  showAnswer() {
    this.answerTarget.hidden = false
    this.showButtonTarget.hidden = true
    this.element.classList.add("is-answer-visible")
  }

  hideAnswer() {
    this.answerTarget.hidden = true
    this.showButtonTarget.hidden = false
    this.element.classList.remove("is-answer-visible")
  }

  toggleAnswer() {
    if (this.answerTarget.hidden) {
      this.showAnswer()
    } else {
        this.hideAnswer()
    }
  }

  handleKeydown(event) {
    if (event.target.matches("input, textarea, select")) return

    if (event.key === " " || event.key === "Enter") {
      event.preventDefault()
      this.toggleAnswer()
      return
    }

    if (event.key === "Escape") {
      this.hideAnswer()
      return
    }

    const button = this.element.querySelector(`[data-review-rating="${event.key}"]`)

    if (button && !this.answerTarget.hidden) {
      button.click()
    }
  }
}
