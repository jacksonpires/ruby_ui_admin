// Boots Stimulus and registers the vendored RubyUI controllers (verbatim) plus RubyUI Admin's
// own `rua--*` controllers, under the identifiers their markup expects. Loaded as a native ES
// module via the importmap in the admin layout — no build step, self-hosted (Stimulus lives
// under vendor/).
import { Application } from "@hotwired/stimulus"

// Self-host Turbo (Drive/Frames/Streams) so the admin navigates without full-page reloads,
// unless the host app already provides Turbo on the page (then reuse it — avoids two instances).
if (!window.Turbo) import("@hotwired/turbo")

import ToasterController from "./ruby_ui--toaster_controller.js"
import ToastController from "./ruby_ui--toast_controller.js"
import SidebarController from "./ruby_ui--sidebar_controller.js"
import SheetController from "./ruby_ui--sheet_controller.js"
import SheetContentController from "./ruby_ui--sheet_content_controller.js"
import ComboboxController from "./ruby_ui--combobox_controller.js"
import TabsController from "./rua--tabs_controller.js"
import DialogController from "./rua--dialog_controller.js"
import BulkSelectController from "./rua--bulk-select_controller.js"
import RowLinkController from "./rua--row-link_controller.js"
import ConfirmController from "./rua--confirm_controller.js"

const application = window.Stimulus || Application.start()
window.Stimulus = application

application.register("ruby-ui--toaster", ToasterController)
application.register("ruby-ui--toast", ToastController)
application.register("ruby-ui--sidebar", SidebarController)
application.register("ruby-ui--sheet", SheetController)
application.register("ruby-ui--sheet-content", SheetContentController)
application.register("ruby-ui--combobox", ComboboxController)
application.register("rua--tabs", TabsController)
application.register("rua--dialog", DialogController)
application.register("rua--bulk-select", BulkSelectController)
application.register("rua--row-link", RowLinkController)
application.register("rua--confirm", ConfirmController)
