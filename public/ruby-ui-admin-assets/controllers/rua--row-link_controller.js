import { Controller } from "@hotwired/stimulus"

// Makes an index row navigate to its show page on click, ignoring clicks on interactive
// children (links/buttons/inputs/labels and open dialogs) so row controls keep working.
// Uses Turbo.visit when Turbo is present (from step H7), else a full navigation.
// Connects to data-controller="rua--row-link".
export default class extends Controller {
  static values = { url: String }

  navigate(event) {
    if (event.target.closest('a, button, input, label, [data-rua-dialog]')) return
    if (!this.urlValue) return
    if (window.Turbo) window.Turbo.visit(this.urlValue)
    else window.location = this.urlValue
  }
}
