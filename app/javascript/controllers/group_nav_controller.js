import { Controller } from "@hotwired/stimulus"

// Jump links and expand/collapse-all above the groups: they talk to each group's group-fold controller
// through custom events, so nothing here depends on how a group is rendered.
export default class extends Controller {
  open(event) {
    document.getElementById(event.params.id)?.dispatchEvent(new CustomEvent("group-fold:open"))
  }

  expandAll() {
    this.broadcast("group-fold:open")
  }

  collapseAll() {
    this.broadcast("group-fold:close")
  }

  broadcast(name) {
    this.element.querySelectorAll("[data-controller~='group-fold']").forEach((group) => {
      group.dispatchEvent(new CustomEvent(name))
    })
  }
}
