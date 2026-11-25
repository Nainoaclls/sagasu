import { Controller } from "@hotwired/stimulus"
import Typed from "typed.js"

// Typing effect (Le Wagon Typed.js pattern) for the landing demo. The final text is in the HTML,
// so screen readers, no-JS users and reduced-motion users get it directly.
// Use: data-controller="typed" on the element whose text should be typed.
export default class extends Controller {
  connect() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return

    this.element.setAttribute("aria-label", this.element.textContent.trim())
    const text = this.element.innerHTML.trim()
    this.element.innerHTML = ""
    this.typed = new Typed(this.element, { strings: [text], typeSpeed: 28, startDelay: 400, showCursor: true, cursorChar: "|" })
  }

  disconnect() {
    this.typed?.destroy()
  }
}
