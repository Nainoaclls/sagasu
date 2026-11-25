import { Controller } from "@hotwired/stimulus"
import "tom-select"

// Searchable select (Le Wagon "Stimulus + Tom Select" pattern) for long lists such as the 47 prefectures.
// The original <select> stays in the form: its value and change events still drive autosubmit and validation.
// Use: data-controller="tom-select" on a <select>.
export default class extends Controller {
  static values = { placeholder: String }

  connect() {
    this.select = new window.TomSelect(this.element, {
      allowEmptyOption: true,
      maxOptions: null,
      placeholder: this.placeholderValue || undefined,
      // The original select keeps its label (TomSelect links it to its own input)
      controlInput: "<input>"
    })
  }

  disconnect() {
    this.select?.destroy()
  }
}
