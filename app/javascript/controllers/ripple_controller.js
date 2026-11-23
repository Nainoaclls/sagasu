import { Controller } from "@hotwired/stimulus"

// Click feedback: a circle spreads from the pointer inside the button.
// Use: data-controller="ripple" data-action="click->ripple#burst"
export default class extends Controller {
  burst(event) {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return

    const rect = this.element.getBoundingClientRect()
    const size = Math.max(rect.width, rect.height)
    const dot = document.createElement("span")
    dot.className = "sg-ripple"
    dot.style.width = dot.style.height = `${size}px`
    dot.style.left = `${(event.clientX || rect.left + rect.width / 2) - rect.left - size / 2}px`
    dot.style.top = `${(event.clientY || rect.top + rect.height / 2) - rect.top - size / 2}px`
    this.element.appendChild(dot)
    dot.addEventListener("animationend", () => dot.remove())
  }
}
