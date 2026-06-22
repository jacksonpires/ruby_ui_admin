import { Controller } from "@hotwired/stimulus"

// Tab group. Without JS the panels stack (each titled by its heading); on connect this reveals
// the tab bar, hides the redundant per-panel headings, and shows one panel at a time. Lazy panels
// hold a `<turbo-frame loading="lazy">` that Turbo loads when the panel becomes visible — this
// controller only switches panels. Connects to data-controller="rua--tabs".
//
// Keys are matched via data-rua-tab="<key>" (buttons) and data-rua-tab-panel="<key>" (panels).
export default class extends Controller {
  static targets = ["tab", "panel", "nav", "heading"]

  connect() {
    this.navTargets.forEach((n) => { n.hidden = false })
    this.headingTargets.forEach((h) => { h.hidden = true })
    if (this.tabTargets.length) this.activate(this.tabTargets[0].dataset.ruaTab)
  }

  show(event) {
    event.preventDefault()
    this.activate(event.currentTarget.dataset.ruaTab)
  }

  activate(key) {
    this.tabTargets.forEach((b) => {
      const on = b.dataset.ruaTab === key
      b.setAttribute("aria-selected", on ? "true" : "false")
      b.classList.toggle("border-primary", on)
      b.classList.toggle("text-foreground", on)
      b.classList.toggle("border-transparent", !on)
      b.classList.toggle("text-muted-foreground", !on)
    })
    this.panelTargets.forEach((p) => {
      p.hidden = p.dataset.ruaTabPanel !== key
    })
  }
}
