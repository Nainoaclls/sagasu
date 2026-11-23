import { Controller } from "@hotwired/stimulus"

// Adds a shadow to the sticky navbar once the page scrolls.
export default class extends Controller {
  connect() {
    this.onScroll = () => this.element.classList.toggle("is-scrolled", window.scrollY > 8)
    window.addEventListener("scroll", this.onScroll, { passive: true })
    this.onScroll()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
  }
}
