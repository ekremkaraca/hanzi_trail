import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { defaultIndex: { type: Number, default: 0 } }

  connect() {
    this.activeIndex = this.defaultIndexValue
    this.showActiveTab()
  }

  select(event) {
    event.preventDefault()
    const target = event.currentTarget
    const index = Number(target.dataset.index || target.closest("[data-index]")?.dataset.index)
    if (Number.isNaN(index)) return
    this.activeIndex = index
    this.showActiveTab()
  }

  showActiveTab() {
    this.tabTargets.forEach((tab, index) => {
      const selected = index === this.activeIndex
      tab.setAttribute("aria-selected", selected ? "true" : "false")
      tab.setAttribute("tabindex", selected ? "0" : "-1")
    })

    this.panelTargets.forEach((panel, index) => {
      panel.hidden = index !== this.activeIndex
    })
  }
}
