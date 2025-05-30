export default {
  mounted() {
    this.abortController = new AbortController();

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

    this.el.addEventListener(
      "toggle",
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
  },

  destroyed() {
    this.abortController.abort();
  },

  updateLocation() {
    const triggerRect = this.trigger.getBoundingClientRect();
    const rect = this.el.getBoundingClientRect();

    let left = triggerRect.left;
    const right = left + rect.width;

    if (right > window.innerWidth) {
      left = Math.max(0, left - (right - window.innerWidth));
    }

    this.el.style.position = "fixed";
    this.el.style.top = `${triggerRect.bottom}px`;
    this.el.style.left = `${left}px`;
  },
};
