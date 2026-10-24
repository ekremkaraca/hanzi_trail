// stimulus-textarea-autogrow — vendored from stimulus-components
// https://github.com/stimulus-components/stimulus-components (MIT license)
// TS types stripped and the shared debounce util inlined for importmap use.
import { Controller } from "@hotwired/stimulus"

function debounce(callback, delay) {
  let timeout

  return (...args) => {
    clearTimeout(timeout)
    timeout = setTimeout(() => callback.apply(this, args), delay)
  }
}

export default class extends Controller {
  static values = {
    resizeDebounceDelay: { type: Number, default: 100 },
  }

  initialize() {
    this.autogrow = this.autogrow.bind(this)
  }

  connect() {
    this.element.style.overflow = "hidden"
    const delay = this.resizeDebounceDelayValue

    this.onResize = delay > 0 ? debounce(this.autogrow, delay) : this.autogrow

    this.autogrow()

    this.element.addEventListener("input", this.autogrow)
    window.addEventListener("resize", this.onResize)
  }

  disconnect() {
    this.element.removeEventListener("input", this.autogrow)
    window.removeEventListener("resize", this.onResize)
  }

  autogrow() {
    this.element.style.height = "auto" // Force re-print before calculating the scrollHeight value.
    this.element.style.height = `${this.element.scrollHeight}px`
  }
}
