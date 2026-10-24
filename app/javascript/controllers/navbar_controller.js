import { Controller } from "@hotwired/stimulus"

// Mobile nav disclosure. CSS media queries handle showing/hiding the
// hamburger and laying out the links by breakpoint; this controller owns
// only the open/closed state on mobile and collapses a stale open menu
// when crossing from desktop into mobile width.
export default class extends Controller {
  static targets = ["links", "toggle"]

  static values = {
    breakpoint: { type: Number, default: 600 }
  }

  connect() {
    this.isMobile = window.innerWidth <= this.breakpointValue
    this.open = false
    this.applyOpenState()
    this.boundHandleResize = this.handleResize.bind(this)
    window.addEventListener("resize", this.boundHandleResize)
  }

  disconnect() {
    window.removeEventListener("resize", this.boundHandleResize)
  }

  toggle() {
    this.open = !this.open
    this.applyOpenState()
  }

  close() {
    if (this.isMobile) {
      this.open = false
      this.applyOpenState()
    }
  }

  handleResize() {
    const wasMobile = this.isMobile
    this.isMobile = window.innerWidth <= this.breakpointValue
    if (this.isMobile && !wasMobile) {
      this.open = false
    }
    this.applyOpenState()
  }

  applyOpenState() {
    if (!this.hasLinksTarget) return

    if (this.isMobile) {
      this.linksTarget.hidden = !this.open
    } else {
      this.linksTarget.hidden = false
    }

    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute("aria-expanded", String(this.open && this.isMobile))
      this.toggleTarget.classList.toggle("nav-open", this.open && this.isMobile)
    }
  }
}
