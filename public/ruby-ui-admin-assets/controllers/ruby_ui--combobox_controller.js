import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="ruby-ui--combobox"
// Vendored from RubyUI; the only change is `updatePopoverPosition`, which uses plain
// getBoundingClientRect positioning instead of @floating-ui/dom (so no bundler/extra dep).
export default class extends Controller {
  static values = {
    term: String,
    minPopoverWidth: { type: Number, default: 240 }
  }

  static targets = [
    "input",
    "toggleAll",
    "popover",
    "item",
    "emptyState",
    "searchInput",
    "trigger",
    "triggerContent"
  ]

  selectedItemIndex = null

  connect() {
    this.updateTriggerContent()
  }

  disconnect() {
    if (this.cleanup) { this.cleanup() }
  }

  handlePopoverToggle(event) {
    this.triggerTarget.ariaExpanded = event.newState === 'open' ? 'true' : 'false'
  }

  inputChanged(e) {
    this.updateTriggerContent()

    if (e.target.type == "radio") {
      this.closePopover()
    }

    if (this.hasToggleAllTarget && !e.target.checked) {
      this.toggleAllTarget.checked = false
    }
  }

  inputContent(input) {
    return input.dataset.text || input.parentElement.textContent
  }

  toggleAllItems() {
    const isChecked = this.toggleAllTarget.checked
    this.inputTargets.forEach(input => input.checked = isChecked)
    this.updateTriggerContent()
  }

  updateTriggerContent() {
    const checkedInputs = this.inputTargets.filter(input => input.checked)

    if (checkedInputs.length === 0) {
      this.triggerContentTarget.innerText = this.triggerTarget.dataset.placeholder
    } else if (this.termValue && checkedInputs.length > 1) {
      this.triggerContentTarget.innerText = `${checkedInputs.length} ${this.termValue}`
    } else {
      this.triggerContentTarget.innerText = checkedInputs.map((input) => this.inputContent(input)).join(", ")
    }
  }

  togglePopover(event) {
    event.preventDefault()

    if (this.triggerTarget.ariaExpanded === "true") {
      this.closePopover()
    } else {
      this.openPopover(event)
    }
  }

  openPopover(event) {
    if (event) event.preventDefault()

    this.updatePopoverPosition()
    this.updatePopoverWidth()
    this.triggerTarget.ariaExpanded = "true"
    this.selectedItemIndex = null
    this.itemTargets.forEach(item => item.ariaCurrent = "false")
    this.popoverTarget.showPopover()
  }

  closePopover() {
    this.triggerTarget.ariaExpanded = "false"
    this.popoverTarget.hidePopover()
  }

  filterItems(e) {
    if (["ArrowDown", "ArrowUp", "Tab", "Enter"].includes(e.key)) {
      return
    }

    const filterTerm = this.searchInputTarget.value.toLowerCase()

    if (this.hasToggleAllTarget) {
      if (filterTerm) this.toggleAllTarget.parentElement.classList.add("hidden")
      else this.toggleAllTarget.parentElement.classList.remove("hidden")
    }

    let resultCount = 0

    this.selectedItemIndex = null

    this.inputTargets.forEach((input) => {
      const text = this.inputContent(input).toLowerCase()

      if (text.indexOf(filterTerm) > -1) {
        input.parentElement.classList.remove("hidden")
        resultCount++
      } else {
        input.parentElement.classList.add("hidden")
      }
    })

    this.emptyStateTarget.classList.toggle("hidden", resultCount !== 0)
  }

  keyDownPressed() {
    if (this.selectedItemIndex !== null) {
      this.selectedItemIndex++
    } else {
      this.selectedItemIndex = 0
    }

    this.focusSelectedInput()
  }

  keyUpPressed() {
    if (this.selectedItemIndex !== null) {
      this.selectedItemIndex--
    } else {
      this.selectedItemIndex = -1
    }

    this.focusSelectedInput()
  }

  focusSelectedInput() {
    const visibleInputs = this.inputTargets.filter(input => !input.parentElement.classList.contains("hidden"))

    this.wrapSelectedInputIndex(visibleInputs.length)

    visibleInputs.forEach((input, index) => {
      if (index == this.selectedItemIndex) {
        input.parentElement.ariaCurrent = "true"
        input.parentElement.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'nearest' })
      } else {
        input.parentElement.ariaCurrent = "false"
      }
    })
  }

  keyEnterPressed(event) {
    event.preventDefault()
    const option = this.itemTargets.find(item => item.ariaCurrent === "true")

    if (option) {
      option.click()
    }
  }

  wrapSelectedInputIndex(length) {
    this.selectedItemIndex = ((this.selectedItemIndex % length) + length) % length
  }

  // Position the popover under the trigger using viewport coordinates. The popover lives in
  // the top layer (native Popover API), so a fixed position relative to the trigger's rect
  // places it correctly without a positioning library.
  updatePopoverPosition() {
    const rect = this.triggerTarget.getBoundingClientRect()
    const width = Math.max(this.triggerTarget.offsetWidth, this.minPopoverWidthValue)
    // Keep the popover within the viewport (pull left when the trigger is near the right edge).
    let left = rect.left
    const maxLeft = window.innerWidth - width - 8
    if (left > maxLeft) left = Math.max(8, maxLeft)
    Object.assign(this.popoverTarget.style, {
      position: "fixed",
      top: `${rect.bottom + 4}px`,
      left: `${left}px`,
      margin: "0"
    })
  }

  updatePopoverWidth() {
    const width = Math.max(this.triggerTarget.offsetWidth, this.minPopoverWidthValue)
    this.popoverTarget.style.width = `${width}px`
  }
}
