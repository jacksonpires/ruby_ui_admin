import { Controller } from "@hotwired/stimulus"

// Destructive-action confirmation via the shared RubyUI AlertDialog. A trigger
//   data-action="click->rua--confirm#request"
//   + data-rua--confirm-message-param="…" [+ data-rua--confirm-heading-param="…"]
// opens the dialog (targets: dialog/title/message) instead of acting immediately; confirming
// re-runs the trigger (submits its form, or follows its href). Without JS the trigger acts
// directly, so the action still works. Connects to data-controller="rua--confirm".
export default class extends Controller {
  static targets = ["dialog", "title", "message"]

  connect() {
    this._onKey = (e) => {
      if (e.key === "Escape" && this.hasDialogTarget && !this.dialogTarget.hidden) this.cancel()
    }
    document.addEventListener("keydown", this._onKey)
  }

  disconnect() {
    document.removeEventListener("keydown", this._onKey)
  }

  request(event) {
    event.preventDefault()
    this._pending = event.currentTarget
    if (this.hasTitleTarget && event.params.heading) this.titleTarget.textContent = event.params.heading
    if (this.hasMessageTarget && event.params.message) this.messageTarget.textContent = event.params.message
    if (this.hasDialogTarget) this.dialogTarget.hidden = false
  }

  confirm(event) {
    event.preventDefault()
    const trigger = this._pending
    this._pending = null
    if (this.hasDialogTarget) this.dialogTarget.hidden = true
    if (!trigger) return

    const form = trigger.closest("form")
    if (form) {
      form.requestSubmit ? form.requestSubmit() : form.submit()
    } else if (trigger.tagName === "A") {
      window.location = trigger.getAttribute("href")
    }
  }

  cancel(event) {
    if (event) event.preventDefault()
    this._pending = null
    if (this.hasDialogTarget) this.dialogTarget.hidden = true
  }
}
