// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "@popperjs/core"
import "bootstrap"
import "sweet_confirm"
import { cleanUpModalBackdrop } from "controllers/modal_controller"

// Safety net: close any open Bootstrap modal before Turbo renders or caches a page,
// so a page refresh never leaves a grey backdrop or a locked scroll behind.
const closeOpenModals = () => {
  document.querySelectorAll(".modal.show").forEach((element) => window.bootstrap?.Modal.getInstance(element)?.dispose())
  document.querySelectorAll(".modal.show").forEach((element) => element.classList.remove("show"))
  cleanUpModalBackdrop()
}
document.addEventListener("turbo:before-render", closeOpenModals)
document.addEventListener("turbo:before-cache", closeOpenModals)

// PWA: offline fallback + installable. Production only, so development never serves stale assets.
if (document.documentElement.dataset.env === "production" && "serviceWorker" in navigator) {
  window.addEventListener("load", () => navigator.serviceWorker.register("/service-worker.js"))
}
