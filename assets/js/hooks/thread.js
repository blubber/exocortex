import morphdom from "morphdom";
import { marked } from "marked";

export default {
  updateMargin(section) {
    if (!section) {
      return;
    }

    this.margin = Math.max(
      0,
      this.scrollContainer.clientHeight - section.offsetHeight,
    );
  },

  setMargin() {
    this.el.style.marginBottom = `max(0px, calc(${this.margin}px - 2.5rem))`;
  },

  mounted() {
    this.abortController = new AbortController();
    this.scrollContainer = document.getElementById("scroll-container");
    this.lastPrompt = null;
    this.margin = 0;

    this.handleEvent("new-prompt", (data) => {
      this.lastPrompt = document.getElementById(data.prompt);
      this.updateMargin(this.lastPrompt);
      requestAnimationFrame(() => {
        this.updateMargin();
        this.lastPrompt.scrollIntoView();
      });
    });

    requestAnimationFrame(() => {
      this.scrollContainer.scrollTop = this.scrollContainer.scrollHeight;
    });
  },

  destroyed() {
    this.abortController.abort();
  },

  updated() {
    this.setMargin();
    requestAnimationFrame(() => {
      this.updateMargin(this.lastPrompt);
      this.setMargin();
    });
  },
};
