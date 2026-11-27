import { Controller } from "@hotwired/stimulus"

// Copies a text (RFQ invitation) to the clipboard and confirms on the button label.
export default class extends Controller {
  static values = { text: String, copiedLabel: String }
  static targets = ["label"]

  copy() {
    navigator.clipboard.writeText(this.textValue).then(() => this.confirm())
  }

  confirm() {
    if (!this.hasLabelTarget) return
    const original = this.labelTarget.textContent
    this.labelTarget.textContent = this.copiedLabelValue
    setTimeout(() => { this.labelTarget.textContent = original }, 2000)
  }
}
