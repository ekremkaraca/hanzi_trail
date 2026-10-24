// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

// Vendored stimulus-components controllers live outside the eager-load
// directory, so they register explicitly.
import AutoSubmit from "stimulus-components/auto-submit"
application.register("auto-submit", AutoSubmit)
