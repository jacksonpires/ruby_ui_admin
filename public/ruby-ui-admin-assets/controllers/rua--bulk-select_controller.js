import { Controller } from "@hotwired/stimulus"

// Bulk row selection on the index table. Reveals the "select all" checkbox (hidden without JS)
// and toggles every record checkbox ([data-rua-row-select]) within this table. The checked ids
// are read by `rua--dialog` (via the shared [data-rua-row-select] hook) when a bulk action runs.
// Connects to data-controller="rua--bulk-select".
export default class extends Controller {
  static targets = ["selectAll"]

  connect() {
    this.selectAllTargets.forEach((el) => { el.hidden = false })
  }

  toggleAll(event) {
    this.element
      .querySelectorAll("[data-rua-row-select]")
      .forEach((cb) => { cb.checked = event.target.checked })
  }
}
