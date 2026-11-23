import { Controller } from "@hotwired/stimulus"

// Live count of materials detected in the paste box (one per non-empty line).
export default class extends Controller {
  static targets = ["input", "count"]

  connect() {
    this.update()
  }

  update() {
    const lines = this.inputTarget.value.split("\n").filter((line) => line.trim() !== "").length
    this.countTarget.textContent = lines === 0 ? "One material per line" : `${lines} material${lines === 1 ? "" : "s"} detected`
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
