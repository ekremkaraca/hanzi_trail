import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["tab", "panel"];
  static classes = ["active"];

  switch(event) {
    event.preventDefault();
    const clickedIndex = parseInt(event.currentTarget.dataset.index);

    // Toggle active state on tabs navigation
    this.tabTargets.forEach((tab, index) => {
      if (index === clickedIndex) {
        tab.classList.add(this.activeClass);
      } else {
        tab.classList.remove(this.activeClass);
      }
    });

    // Toggle panel view states via Bulma's hidden helper
    this.panelTargets.forEach((panel, index) => {
      if (index === clickedIndex) {
        panel.classList.remove("is-hidden");
      } else {
        panel.classList.add("is-hidden");
      }
    });
  }
}
