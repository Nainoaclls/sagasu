import { Controller } from "@hotwired/stimulus"

// Dashboard: filters project cards by status with tabs, and announces the result count.
export default class extends Controller {
  static targets = ["item", "tab", "empty", "status"]

  select(event) {
    const status = event.currentTarget.dataset.status
    this.tabTargets.forEach((tab) => tab.setAttribute("aria-pressed", String(tab === event.currentTarget)))

    let shown = 0
    this.itemTargets.forEach((item) => {
      const match = status === "all" || item.dataset.status === status
      item.hidden = !match
      if (match) shown += 1
    })

    if (this.hasEmptyTarget) this.emptyTarget.hidden = shown > 0
    if (this.hasStatusTarget) this.statusTarget.textContent = `${shown} project${shown === 1 ? "" : "s"} shown`
  }
}
