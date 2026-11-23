import { Controller } from "@hotwired/stimulus"

// Fades sections in as they scroll into view. Children with .sg-reveal are staggered.
// Use: data-controller="reveal" on a container.
export default class extends Controller {
  connect() {
    this.items = [...this.element.querySelectorAll(".sg-reveal")]
    if (this.element.classList.contains("sg-reveal")) this.items.unshift(this.element)

    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    if (reduce || !("IntersectionObserver" in window)) {
      this.items.forEach((item) => item.classList.add("is-visible"))
      return
    }

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return
        entry.target.classList.add("is-visible")
        this.observer.unobserve(entry.target)
      })
    }, { threshold: 0.12, rootMargin: "0px 0px -40px 0px" })

    this.items.forEach((item, index) => {
      if (!item.style.getPropertyValue("--delay")) item.style.setProperty("--delay", `${(index % 6) * 70}ms`)
      this.observer.observe(item)
    })
  }

  disconnect() {
    this.observer?.disconnect()
  }
}
