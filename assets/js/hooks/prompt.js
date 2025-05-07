export default {
  mounted() {
    this.abortController = new AbortController();

    this.el.addEventListener("keypress", (event) => {
      if (event.key === "Enter" && !event.shiftKey) {
        document.getElementById("submit-prompt").click();
        event.preventDefault();
      }
    });
  },

  destroyed() {
    this.abortController.abort();
  },
};
