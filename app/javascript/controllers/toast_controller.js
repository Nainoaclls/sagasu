import { Controller } from "@hotwired/stimulus"

// Flash message that closes by itself. Pauses while hovered or focused so it can be read.
export default class extends Controller {
  static values = { delay: { type: Number, default: 6000 } }

  connect() {
    this.element.style.setProperty("--toast-delay", `${this.delayValue}ms`)
    this.remaining = this.delayValue
    this.start()
  }

  start() {
    this.startedAt = Date.now()
    this.timer = setTimeout(() => this.close(), this.remaining)
  }

  pause() {
    clearTimeout(this.timer)
    this.remaining -= Date.now() - this.startedAt
  }

  resume() {
    this.start()
  }

  close() {
    clearTimeout(this.timer)
    this.element.classList.add("is-leaving")
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    setTimeout(() => this.element.remove(), reduce ? 0 : 200)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
