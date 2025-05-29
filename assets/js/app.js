import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

import Dialog from "./hooks/dialog.js";
import List from "./hooks/list.js";
import Prompt from "./hooks/prompt.js";
import Thread from "./hooks/thread.js";
import Markdown from "./hooks/markdown.js";

const Hooks = { Dialog, List, Prompt, Thread, Markdown };

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

liveSocket.connect();

window.liveSocket = liveSocket;

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener(
    "phx:live_reload:attached",
    ({ detail: reloader }) => {
      // Enable server log streaming to client.
      // Disable with reloader.disableServerLogs()
      reloader.enableServerLogs();

      // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
      //
      //   * click with "c" key pressed to open at caller location
      //   * click with "d" key pressed to open at function component definition location
      // let keyDown;
      // window.addEventListener("keydown", (e) => (keyDown = e.key));
      // window.addEventListener("keyup", (e) => (keyDown = null));
      // window.addEventListener(
      //   "click",
      //   (e) => {
      //     if (keyDown === "c") {
      //       e.preventDefault();
      //       e.stopImmediatePropagation();
      //       reloader.openEditorAtCaller(e.target);
      //     } else if (keyDown === "d") {
      //       e.preventDefault();
      //       e.stopImmediatePropagation();
      //       reloader.openEditorAtDef(e.target);
      //     }
      //   },
      //   true,
      // );

      window.liveReloader = reloader;
    },
  );
}

document.addEventListener("DOMContentLoaded", () => {
  const cache = {};
  const exceptions = ["/"];

  window.addEventListener("keydown", (event) => {
    if (
      (event.keyCode < 65 || event.keyCode > 90) &&
      !exceptions.includes(event.key)
    ) {
      return;
    }
    let shortcut = "";

    if (event.ctrlKey || event.metaKey) {
      shortcut = "M";
    }

    if (event.shiftKey) {
      shortcut += "S";
    }

    shortcut += event.key;
    let target = cache[shortcut];

    if (
      target === undefined ||
      !target.isConnected ||
      target.dataset.kb !== shortcut
    ) {
      cache[shortcut] = undefined;
      target = document.querySelector(`[data-kb="${shortcut}"]`);
    }

    if (!target) {
      return;
    }

    cache[shortcut] = target;

    event.preventDefault();

    switch (target.dataset.kbAction ?? "click") {
      case "click":
        target.click();
        break;

      case "focus":
        target.focus();
        break;
    }
  });
});
