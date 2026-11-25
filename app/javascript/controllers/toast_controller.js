import { Controller } from "@hotwired/stimulus"

// Shows a Bootstrap toast as soon as it is on the page (flash, Turbo Stream or broadcast),
// and removes it from the DOM once hidden. Bootstrap handles the timer, hover and focus pause.
export default class extends Controller {
  connect() {
    this.removeOnHide = () => this.element.remove()
    this.element.addEventListener("hidden.bs.toast", this.removeOnHide)
    window.bootstrap?.Toast.getOrCreateInstance(this.element).show()
  }

  disconnect() {
    this.element.removeEventListener("hidden.bs.toast", this.removeOnHide)
    window.bootstrap?.Toast.getInstance(this.element)?.dispose()
  }
}
