import { Controller } from "@hotwired/stimulus"

// A group card that folds. The choice is kept in sessionStorage so it survives the Turbo Stream
// replacements that follow every action; the server only provides the default (open-value).
export default class extends Controller {
  static targets = ["body", "toggle"]
  static values = { key: String, open: Boolean }

  connect() {
    const stored = this.read()
    this.render(stored === null ? this.openValue : stored === "1")
  }

  toggle() {
    this.set(this.bodyTarget.hidden)
  }

  // Click on the header (title area, counts) toggles too, except on links and buttons inside it
  headerClick(event) {
    if (event.target.closest("a, button, form, input, select, textarea")) return
    this.toggle()
  }

  open() {
    this.set(true)
  }

  close() {
    this.set(false)
  }

  // Working inside a group (selecting, declining, searching) keeps it open after its card is replaced
  keep() {
    if (!this.bodyTarget.hidden) this.write(true)
  }

  set(open) {
    this.render(open)
    this.write(open)
  }

  render(open) {
    this.bodyTarget.hidden = !open
    this.toggleTarget.setAttribute("aria-expanded", String(open))
    this.element.classList.toggle("is-collapsed", !open)
  }

  read() {
    try { return sessionStorage.getItem(`sg-fold-${this.keyValue}`) } catch { return null }
  }

  write(open) {
    try { sessionStorage.setItem(`sg-fold-${this.keyValue}`, open ? "1" : "0") } catch { /* private mode */ }
  }
}
