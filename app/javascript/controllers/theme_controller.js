import { Controller } from "@hotwired/stimulus"

// Light/dark theme. The stored choice wins; without one the OS preference applies.
// The inline script in the layout head paints the first frame; this controller handles
// toggles and keeps the button state and <meta name="theme-color"> in sync.
export default class extends Controller {
  static targets = ["icon"]
  static values = { toDark: String, toLight: String }

  connect() {
    this.media = window.matchMedia("(prefers-color-scheme: dark)")
    this.followOs = () => {
      if (!this.stored) this.apply(this.media.matches ? "dark" : "light")
    }
    this.media.addEventListener("change", this.followOs)
    this.sync()
  }

  disconnect() {
    this.media?.removeEventListener("change", this.followOs)
  }

  toggle() {
    const next = this.current === "dark" ? "light" : "dark"
    try { localStorage.setItem("sg-theme", next) } catch (e) { /* private browsing */ }
    this.apply(next)
  }

  get stored() {
    try { return localStorage.getItem("sg-theme") } catch (e) { return null }
  }

  get current() {
    return document.documentElement.dataset.bsTheme === "dark" ? "dark" : "light"
  }

  apply(theme) {
    document.documentElement.dataset.bsTheme = theme
    this.sync()
  }

  sync() {
    const dark = this.current === "dark"
    document.querySelector('meta[name="theme-color"]')?.setAttribute("content", dark ? "#121E25" : "#326273")
    this.element.setAttribute("aria-pressed", String(dark))
    this.element.setAttribute("aria-label", dark ? this.toLightValue : this.toDarkValue)
    if (this.hasIconTarget) this.iconTarget.className = `fa-solid ${dark ? "fa-sun" : "fa-moon"}`
  }
}
