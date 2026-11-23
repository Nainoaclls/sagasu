import { Controller } from "@hotwired/stimulus"

// The hero demo card leans toward the mouse. CSS reads --rx and --ry.
// Use: data-controller="tilt" data-action="mousemove->tilt#move mouseleave->tilt#reset"
export default class extends Controller {
  move(event) {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return

    const rect = this.element.getBoundingClientRect()
    const x = ((event.clientX - rect.left) / rect.width) * 2 - 1
    const y = ((event.clientY - rect.top) / rect.height) * 2 - 1
    this.element.style.setProperty("--ry", `${(x * 5).toFixed(2)}deg`)
    this.element.style.setProperty("--rx", `${(-y * 4).toFixed(2)}deg`)
  }

  reset() {
    this.element.style.setProperty("--ry", "0deg")
    this.element.style.setProperty("--rx", "0deg")
  }
}
