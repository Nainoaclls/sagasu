import { Controller } from "@hotwired/stimulus"

// Submits the form while the user types (debounced) or when a select changes.
// Use: data-controller="autosubmit" on the form,
//   data-action="input->autosubmit#debounced" on text fields, "change->autosubmit#now" on selects.
export default class extends Controller {
  static values = { wait: { type: Number, default: 280 } }

  debounced() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.element.requestSubmit(), this.waitValue)
  }

  now() {
    clearTimeout(this.timer)
    this.element.requestSubmit()
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
