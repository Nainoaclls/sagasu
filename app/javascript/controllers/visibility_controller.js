import { Controller } from "@hotwired/stimulus"

// Review form: the project select appears only when "Only this project" is chosen.
export default class extends Controller {
  static targets = ["project", "select"]

  connect() {
    this.toggle()
  }

  toggle() {
    const checked = this.element.querySelector("input[name='review[visibility]']:checked")
    const projectOnly = checked?.value === "project"
    this.projectTarget.hidden = !projectOnly
    this.selectTarget.required = projectOnly
  }
}
