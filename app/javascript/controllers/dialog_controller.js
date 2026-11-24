import { Controller } from "@hotwired/stimulus"

// Opens a native <dialog> (focus trap, Escape to close) and gives focus back to the opener.
// Use: data-controller="dialog" with a dialog target, data-action="dialog#open" on the button.
// A form inside the dialog should call dialog#release on submit (see below).
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

  // On form submit: close the modal properly WITHOUT cancelling the submission.
  // If the page refresh (Turbo morph) removed the "open" attribute of a modal dialog instead,
  // the browser would keep the page inert and nothing would be clickable anymore.
  release() {
    if (this.dialogTarget.open) this.dialogTarget.close()
  }

  // Click on the backdrop closes the dialog
  backdrop(event) {
    if (event.target === this.dialogTarget) this.dialogTarget.close()
  }

  restoreFocus() {
    this.opener?.focus()
  }

  disconnect() {
    if (this.hasDialogTarget && this.dialogTarget.open) this.dialogTarget.close()
  }
}
