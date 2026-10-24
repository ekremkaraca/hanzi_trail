// stimulus-auto-submit — vendored from stimulus-components
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
    delay: { type: Number, default: 150 },
  }

  // Wrapping happens here rather than in connect(): Stimulus reuses the
  // controller instance when the same element re-enters the DOM, so connect()
  // would debounce the already-debounced submit and compound the delay.
  initialize() {
    const submit = this.submit.bind(this)

    this.submit = this.delayValue > 0 ? debounce(submit, this.delayValue) : submit
  }

  submit() {
    this.element.requestSubmit()
  }
}
