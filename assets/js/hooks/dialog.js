export default {
  mounted() {
    this.abortController = new AbortController();
    this.open = false;

    this.el.addEventListener(
      ":open",
      () => {
        this.open = true;
        this.el.showModal();
      },
      { signal: this.abortController.signal },
    );

    this.el.addEventListener(
      ":close",
      () => {
        this.open = false;
        this.el.close();
      },
      { signal: this.abortController.signal },
    );
  },

  destroyed() {
    this.abortController.abort();
  },

  beforeUpdate() {
    this.open = this.el.hasAttribute("open");
  },

  updated() {
    if (this.open) {
      this.el.showModal();
    } else {
      this.el.close();
    }
  },
};
