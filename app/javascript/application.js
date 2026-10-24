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

// Character counter wrapper.
// Usage:
//   <div x-data="textCounter(500)">
//     <%= form.text_area :story, "x-ref": "field" %>
//     <p :class="overLimit && 'char-counter--warning'">
//       <span x-text="count"></span> / 500
//     </p>
//   </div>
// The wrapper holds the counter state and reads the field via $refs.field.
// `overLimit` flips on when the current length meets or exceeds the soft
// cap; server validation remains the source of truth for the hard cap.
Alpine.data("textCounter", (limit) => ({
  count: 0,
  limit: Number(limit) || Infinity,

  init() {
    this.syncFromField()
    this.$refs.field.addEventListener("input", () => this.syncFromField())
  },

  syncFromField() {
    this.count = (this.$refs.field.value || "").length
  },

  get overLimit() {
    return Number.isFinite(this.limit) && this.count >= this.limit
  },
}))

window.Alpine = Alpine
Alpine.start()
