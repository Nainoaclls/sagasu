import { Controller } from "@hotwired/stimulus"

// A number that counts up from 0 when it scrolls into view.
// The server-rendered text is the final value, so screen readers and no-JS users get it directly.
export default class extends Controller {
  static values = { end: Number, duration: { type: Number, default: 1100 } }

  connect() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return
    if (!("IntersectionObserver" in window)) return

    this.final = this.element.textContent
    this.observer = new IntersectionObserver(([entry]) => {
      if (!entry.isIntersecting) return
      this.observer.disconnect()
      this.run()
    }, { threshold: 0.4 })
    this.observer.observe(this.element)
  }

  run() {
    const start = performance.now()
    const format = new Intl.NumberFormat("en-US")
    const tick = (now) => {
      const progress = Math.min((now - start) / this.durationValue, 1)
      const eased = 1 - Math.pow(1 - progress, 3)
      this.element.textContent = format.format(Math.round(this.endValue * eased))
      if (progress < 1) {
        this.frame = requestAnimationFrame(tick)
      } else {
        this.element.textContent = this.final
      }
    }
    this.frame = requestAnimationFrame(tick)
  }

  disconnect() {
    this.observer?.disconnect()
    cancelAnimationFrame(this.frame)
    if (this.final) this.element.textContent = this.final
  }
}
