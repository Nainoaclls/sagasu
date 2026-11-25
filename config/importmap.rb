# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "bootstrap", to: "bootstrap.min.js", preload: true
pin "@popperjs/core", to: "popper.js", preload: true
pin "sweet_confirm" # app/javascript/sweet_confirm.js: data-turbo-confirm with SweetAlert2
pin "sweetalert2" # @11.26.26
pin "typed.js" # @3.0.0
pin "tom-select", to: "tom-select.complete.min.js" # @2.7.0 self-contained build, sets window.TomSelect
