import { Controller } from "@hotwired/stimulus"

// Manages the lazy action modals within its scope (the page content wrapper). A trigger
//   data-action="click->rua--dialog#open" + data-rua--dialog-id-param="<id>" [+ ...-bulk-param="true"]
// opens the dialog [data-rua-dialog="<id>"]; the action form lives in a <turbo-frame> inside it.
// Non-bulk frames carry a static `src` + loading="lazy", so Turbo loads them when the dialog
// becomes visible. Bulk frames have no `src` server-side (the selection isn't known then) — this
// controller sets it from the checked rows on open, so the action's fields aren't evaluated until
// the modal opens. Closes on any element with data-action="click->rua--dialog#close" (backdrop /
// ✕ / cancel) or the Escape key.
//
// Connects to data-controller="rua--dialog".
export default class extends Controller {
  connect() {
    this._onKey = (e) => { if (e.key === "Escape") this.closeAll() }
    document.addEventListener("keydown", this._onKey)
  }

  disconnect() {
    document.removeEventListener("keydown", this._onKey)
  }

  open(event) {
    event.preventDefault()
    const dialog = this.element.querySelector(`[data-rua-dialog="${CSS.escape(event.params.id)}"]`)
    if (!dialog) return
    if (event.params.bulk === true) this.loadBulkFrame(dialog)
    dialog.hidden = false
  }

  close(event) {
    const dialog = event.target.closest("[data-rua-dialog]")
    if (!dialog) return
    event.preventDefault()
    dialog.hidden = true
  }

  closeAll() {
    this.element.querySelectorAll("[data-rua-dialog]:not([hidden])").forEach((d) => { d.hidden = true })
  }

  // Point the bulk dialog's <turbo-frame> at its base url + the currently checked rows. Setting
  // `src` makes Turbo (re)load the frame, so reopening with a different selection refetches.
  loadBulkFrame(dialog) {
    const frame = dialog.querySelector("turbo-frame[data-rua-frame-base]")
    if (!frame) return
    const ids = this.selectedIds().map((id) => "record_ids[]=" + encodeURIComponent(id))
    frame.setAttribute("src", frame.dataset.ruaFrameBase + (ids.length ? "&" + ids.join("&") : ""))
  }

  // Checked bulk-selection ids, read from the shared [data-rua-row-select] hooks.
  selectedIds() {
    return Array.from(document.querySelectorAll("[data-rua-row-select]:checked")).map((cb) => cb.value)
  }
}
