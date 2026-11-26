import { Controller } from "@hotwired/stimulus"

// Live count of materials detected in the paste box (one per non-empty line).
// The texts come from the view (data-*-value) so this controller stays language-agnostic.
export default class extends Controller {
  static targets = ["input", "count"]
  static values = { emptyText: String, countTextOne: String, countTextOther: String }

  connect() {
    this.update()
  }

  update() {
    const lines = this.inputTarget.value.split("\n").filter((line) => line.trim() !== "").length
    const template = lines === 0 ? this.emptyTextValue
      : lines === 1 ? this.countTextOneValue
      : this.countTextOtherValue
    this.countTarget.textContent = template.replace("%{count}", lines)
    this.countTarget.classList.toggle("is-ready", lines > 0)
  }

  // Fills the box with an example so the demo starts fast
  example(event) {
    event.preventDefault()
    this.inputTarget.value = event.currentTarget.dataset.example.replaceAll("\\n", "\n")
    this.inputTarget.focus()
    this.update()
  }
}
