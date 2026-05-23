import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="review"
export default class extends Controller {
  static targets = ["answer", "showButton"]

  showAnswer() {
    this.answerTarget.hidden = false
    this.element.classList.add("is-answer-visible")

    if (this.hasShowButtonTarget) {
      this.showButtonTarget.textContent = "Hide answer"
    }
  }

  hideAnswer() {
    this.answerTarget.hidden = true
    this.element.classList.remove("is-answer-visible")

    if (this.hasShowButtonTarget) {
      this.showButtonTarget.textContent = "Show answer"
    }
  }

  toggleAnswer() {
    if (this.answerTarget.hidden) {
      this.showAnswer()
    } else {
        this.hideAnswer()
    }
  }

  handleKeydown(event) {
    if (this.shouldIgnoreKeydown(event)) return

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
      event.preventDefault()
      button.click()
    }
  }

  shouldIgnoreKeydown(event) {
    return event.target.matches("input, textarea, select, button")
  }
}
