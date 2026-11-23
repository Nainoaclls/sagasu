import { Controller } from "@hotwired/stimulus"

// Shows the "Sagasu is searching…" overlay while an AI form is submitted, and blocks double clicks.
// Use on a form: data-controller="ai-busy" data-ai-busy-message-value="Grouping your materials"
//   data-action="turbo:submit-start->ai-busy#start turbo:submit-end->ai-busy#stop"
export default class extends Controller {
  static values = { message: String }

  start() {
    this.button = this.element.querySelector("[type=submit]")
    this.button?.classList.add("is-busy")
    this.button?.setAttribute("aria-disabled", "true")

    const overlay = document.getElementById("ai-overlay")
    if (!overlay) return
    overlay.querySelector("[data-ai-message]").textContent = this.messageValue || "Sagasu is working"
    overlay.hidden = false
  }

  stop(event) {
    // On success the page refreshes and the overlay is rendered hidden again.
    if (event.detail?.success) return

    this.button?.classList.remove("is-busy")
    this.button?.removeAttribute("aria-disabled")
    const overlay = document.getElementById("ai-overlay")
    if (overlay) overlay.hidden = true
  }
}
