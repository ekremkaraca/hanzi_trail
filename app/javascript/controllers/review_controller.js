import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="review"
export default class extends Controller {
  static targets = ["answer", "showButton"]

  showAnswer() {
    this.answerTarget.classList.remove("is-hidden")
    this.showButtonTarget.classList.add("is-hidden")
  }
}
