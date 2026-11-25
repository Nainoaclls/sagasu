import { Controller } from "@hotwired/stimulus"

// Bootstrap modal opened with data-bs-toggle="modal". This controller only closes it cleanly:
// on form submit (before the Turbo Stream replaces the card that contains it) and on disconnect,
// so no grey backdrop or locked scroll is left behind.
export default class extends Controller {
  hide() {
    window.bootstrap?.Modal.getInstance(this.element)?.hide()
  }

  disconnect() {
    const modal = window.bootstrap?.Modal.getInstance(this.element)
    if (!modal) return

    modal.dispose()
    cleanUpModalBackdrop()
  }
}

// Removes what Bootstrap adds to <body> while a modal is open
export function cleanUpModalBackdrop() {
  if (document.querySelector(".modal.show")) return

  document.querySelectorAll(".modal-backdrop").forEach((backdrop) => backdrop.remove())
  document.body.classList.remove("modal-open")
  document.body.style.removeProperty("overflow")
  document.body.style.removeProperty("padding-right")
}
