import "@hotwired/turbo-rails"
import "controllers"

import Alpine from "alpinejs"

Alpine.data("reviewCard", () => ({
  answerVisible: false,

  init() {
    // Listen for toggle requests from the Show/Hide button or keyboard
    // shortcuts handled by the Stimulus review controller.
    window.addEventListener("review:toggle", () => {
      this.answerVisible = !this.answerVisible
    })

    // Mirror visibility changes to the Stimulus controller so its keyboard
    // handler can gate the 1–4 rating keypresses.
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
