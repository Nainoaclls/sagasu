import { Controller } from "@hotwired/stimulus"

// Landing page: plays the product story step by step (need > groups > suggestions > approval), then loops.
// All steps are in the HTML; without JS or with reduced motion, they are simply all visible.
export default class extends Controller {
  static targets = ["step"]
  static values = { interval: { type: Number, default: 1400 } }

  connect() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return

    this.element.classList.add("is-playing")
    this.index = 0
    this.play()
  }

  play() {
    this.stepTargets.forEach((step) => step.classList.remove("is-shown"))
    this.index = 0
    this.next()
  }

  next() {
    if (this.index < this.stepTargets.length) {
      this.stepTargets[this.index].classList.add("is-shown")
      this.index += 1
      this.timer = setTimeout(() => this.next(), this.intervalValue)
    } else {
      this.timer = setTimeout(() => this.play(), this.intervalValue * 3)
    }
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
