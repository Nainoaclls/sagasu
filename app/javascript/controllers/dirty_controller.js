import { Controller } from "@hotwired/stimulus"

// Inline edit: shows the Save button only once the value changed; Escape restores it.
export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.original = this.inputTarget.value
  }

  check() {
    this.element.classList.toggle("is-dirty", this.inputTarget.value !== this.original)
  }

  cancel(event) {
    if (event.key !== "Escape") return
    this.inputTarget.value = this.original
    this.check()
    this.inputTarget.blur()
  }
}
