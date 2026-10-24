// stimulus-character-counter — vendored from stimulus-components
// https://github.com/stimulus-components/stimulus-components (MIT license)
// TS types stripped for importmap use; behavior unchanged.
import { Controller } from "@hotwired/stimulus"

const COUNT_UNITS = ["code-units", "code-points", "graphemes"]

export default class extends Controller {
  static targets = ["input", "counter"]
  static values = {
    countdown: Boolean,
    countUnit: { type: String, default: "code-units" },
  }

  initialize() {
    this.update = this.update.bind(this)
  }

  connect() {
    if (COUNT_UNITS.indexOf(this.countUnitValue) === -1) {
      console.error(
        `[stimulus-character-counter] Unknown count unit: ${this.countUnitValue}. Valid units are: ${COUNT_UNITS.join(", ")}. Falling back to code-units.`
      )
    }

    if (this.countUnitValue === "graphemes") {
      const Segmenter = Intl.Segmenter

      if (Segmenter) {
        this.segmenter = new Segmenter(undefined, { granularity: "grapheme" })
      } else {
        console.error(
          "[stimulus-character-counter] Intl.Segmenter is not supported by this browser. Falling back to code-points."
        )
      }
    }

    this.update()
    this.inputTarget.addEventListener("input", this.update)
  }

  disconnect() {
    this.inputTarget.removeEventListener("input", this.update)
    this.segmenter = undefined
  }

  update() {
    this.counterTarget.innerHTML = this.count.toLocaleString()
  }

  get count() {
    let value = this.inputLength

    if (this.hasCountdownValue) {
      if (this.maxLength < 0) {
        console.error(
          `[stimulus-character-counter] You need to add a maxlength attribute on the input to use countdown mode. The current value is: ${this.maxLength}.`
        )
      }

      value = Math.max(this.maxLength - value, 0)
    }

    return value
  }

  get inputLength() {
    const value = this.inputTarget.value

    switch (this.countUnitValue) {
      case "graphemes":
        return this.segmenter ? [...this.segmenter.segment(value)].length : [...value].length
      case "code-points":
        return [...value].length
      default:
        return value.length
    }
  }

  get maxLength() {
    return this.inputTarget.maxLength
  }
}
