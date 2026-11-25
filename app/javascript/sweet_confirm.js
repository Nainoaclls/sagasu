import { Turbo } from "@hotwired/turbo-rails"
import Swal from "sweetalert2"

// Every data-turbo-confirm in the app opens a SweetAlert2 dialog instead of the browser's own
// (same approach as InTrainView). Messages that start with "Remove" or "Delete" get the danger style.
function ask(message, element, submitter) {
  const danger = /^(delete|remove)/i.test(message)
  const label =
    (submitter && submitter.dataset.confirmLabel) ||
    (element && element.dataset && element.dataset.confirmLabel) ||
    (danger ? "Remove" : "Yes, continue")

  return Swal.fire({
    title: message,
    icon: danger ? "warning" : "question",
    showCancelButton: true,
    confirmButtonText: label,
    cancelButtonText: "Cancel",
    reverseButtons: true,
    focusCancel: danger,
    buttonsStyling: false,
    customClass: {
      popup: "sg-swal",
      title: "sg-swal-title",
      actions: "gap-2",
      confirmButton: danger ? "btn btn-danger" : "btn btn-accent",
      cancelButton: "btn btn-outline-primary"
    }
  }).then((result) => result.isConfirmed)
}

// Turbo 8.0.13+ reads Turbo.config.forms.confirm, older versions use setConfirmMethod
if (Turbo.config && Turbo.config.forms) {
  Turbo.config.forms.confirm = ask
} else {
  Turbo.setConfirmMethod(ask)
}
