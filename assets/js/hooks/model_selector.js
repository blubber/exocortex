export default {
  mounted() {
    this.abortController = new AbortController();

    if (!("anchor-name" in document.documentElement.style)) {
      this.trigger = document.querySelector('[popovertarget="model-selector"]');

      this.el.addEventListener(
        "beforetoggle",
        (event) => {
          if (event.newState === "open") {
            this.updateLocation();
          }
        },
        { signal: this.abortController.signal },
      );

      window.addEventListener(
        "resize",
        () => {
          if (this.el.matches(":popover-open")) {
            this.updateLocation();
          }
        },
        { signal: this.abortController.signal },
      );
    }
  },

  destroyed() {
    this.abortController.abort();
  },

  updateLocation() {
    const rect = this.trigger.getBoundingClientRect();

    this.el.style.position = "fixed";
    this.el.style.top = `${rect.bottom}px`;
    this.el.style.left = `${rect.left}px`;
  },
};
