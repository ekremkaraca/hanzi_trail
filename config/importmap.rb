# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "speech/voices", to: "speech/voices.js"
pin "stimulus-components/auto-submit", to: "stimulus-components/auto-submit.js"
pin "stimulus-components/character-counter", to: "stimulus-components/character-counter.js"
pin "stimulus-components/textarea-autogrow", to: "stimulus-components/textarea-autogrow.js"
pin_all_from "app/javascript/controllers", under: "controllers"
