import { Controller } from "@hotwired/stimulus"

// Owns the open/closed state of a collapsible box. The server renders
// the initial state - aria-expanded on the header, the caret class, the
// body's hidden attribute - so the DOM is the state: toggle reads the
// body's current hidden flag and flips it together with the two
// affordances that mirror it.
export default class extends Controller {
  static targets = ["body", "caret"]

  toggle(event) {
    const open = this.bodyTarget.hidden

    this.bodyTarget.hidden = !open
    this.caretTarget.classList.toggle("collapsible-caret--open", open)
    event.currentTarget.setAttribute("aria-expanded", String(open))
  }
}
