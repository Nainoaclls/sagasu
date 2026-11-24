// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "@popperjs/core"
import "bootstrap"

// Safety net: close any open modal <dialog> before Turbo renders or refreshes the page.
// A modal whose "open" attribute is removed by a morph refresh leaves the page inert (frozen).
const closeOpenDialogs = () => document.querySelectorAll("dialog[open]").forEach((dialog) => dialog.close())
document.addEventListener("turbo:before-render", closeOpenDialogs)
document.addEventListener("turbo:before-cache", closeOpenDialogs)
