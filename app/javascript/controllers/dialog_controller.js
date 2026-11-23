import { Controller } from "@hotwired/stimulus"

// Opens a native <dialog> (focus trap, Escape to close) and gives focus back to the opener.
// Use: data-controller="dialog" with a dialog target, data-action="dialog#open" on the button.
export default class extends Controller {
  static targets = ["dialog"]

  open(event) {
    event?.preventDefault()
    this.opener = event?.currentTarget
    this.dialogTarget.showModal()
  }

  close(event) {
    event?.preventDefault()
    this.dialogTarget.close()
  }

  // Click on the backdrop closes the dialog
  backdrop(event) {
    if (event.target === this.dialogTarget) this.dialogTarget.close()
  }

  restoreFocus() {
    this.opener?.focus()
  }
}
