import { Controller } from "@hotwired/stimulus"

// Anything that folds: a group card, or a whole section (materials, groups). The choice is kept in
// sessionStorage so it survives the Turbo Stream replacements that follow every action.
//
// The server provides the default (open-value). With follow-default-value (sections), a change of that
// default between two renders wins over the stored choice: when the project moves to the next step, the
// sections follow it. Group cards keep what the buyer chose, so a card never closes under their hands.
export default class extends Controller {
  static targets = ["body", "toggle"]
  static values = { key: String, open: Boolean, followDefault: Boolean }

  connect() {
    // A page refresh (morph) must not reset folds to the server's default: keep the client's state attributes
    this.keepStateOnMorph = (event) => {
      const stateAttribute = ["hidden", "class", "aria-expanded"].includes(event.detail.attributeName)
      if (stateAttribute && event.target.matches("[data-group-fold-target], [data-controller~='group-fold']")) {
        event.preventDefault()
      }
    }
    this.element.addEventListener("turbo:before-morph-attribute", this.keepStateOnMorph)
    this.render(this.resolve(this.read()))
  }

  disconnect() {
    this.element.removeEventListener("turbo:before-morph-attribute", this.keepStateOnMorph)
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

  // Working inside a card (selecting, declining, searching) keeps it open after it is replaced
  keep() {
    if (!this.bodyTarget.hidden) this.write(true)
  }

  set(open) {
    this.render(open)
    this.write(open)
  }

  // Stored value: two characters, "<open><default it was made under>", e.g. "10"
  resolve(stored) {
    if (stored === null) return this.openValue
    const defaultChanged = stored.length > 1 && (stored[1] === "1") !== this.openValue
    if (this.followDefaultValue && defaultChanged) {
      this.clear()
      return this.openValue
    }
    return stored[0] === "1"
  }

  render(open) {
    this.bodyTarget.hidden = !open
    this.toggleTarget.setAttribute("aria-expanded", String(open))
    this.element.classList.toggle("is-collapsed", !open)
  }

  read() {
    try { return sessionStorage.getItem(this.storageKey) } catch { return null }
  }

  write(open) {
    try { sessionStorage.setItem(this.storageKey, `${open ? "1" : "0"}${this.openValue ? "1" : "0"}`) } catch { /* private mode */ }
  }

  clear() {
    try { sessionStorage.removeItem(this.storageKey) } catch { /* private mode */ }
  }

  get storageKey() {
    return `sg-fold-${this.keyValue}`
  }
}
