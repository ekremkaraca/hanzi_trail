import "@hotwired/turbo-rails"
import "controllers"

import Alpine from "alpinejs"

// Review card: toggles the answer panel and mirrors visibility out to the
// Stimulus review controller for keyboard-shortcut gating.
Alpine.data("reviewCard", () => ({
  answerVisible: false,

  init() {
    window.addEventListener("review:toggle", () => {
      this.answerVisible = !this.answerVisible
    })

    this.$watch("answerVisible", (value) => {
      window.dispatchEvent(
        new CustomEvent("review:visibility-changed", { detail: { visible: value } }),
      )
    })
  },

  show() {
    this.answerVisible = true
  },

  hide() {
    this.answerVisible = false
  },
}))

window.Alpine = Alpine
Alpine.start()
