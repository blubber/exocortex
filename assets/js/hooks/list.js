export default {
  updateFilter() {
    const pattern = new RegExp(this.search.value.split(/\s+/).join(".*"), "i");
    const items = this.el.querySelectorAll("li");

    items.forEach((item) => {
      if (pattern.test(item.dataset.listItem)) {
        item.classList.remove("hidden");
      } else {
        item.classList.add("hidden");
      }
    });
  },
  moveFocusUp() {
    const items = this.el.querySelectorAll("li:not(.hidden)");

    if (items.length === 0) {
      return;
    }

    let focusItem = null;
    if (this.el.contains(document.activeElement)) {
      focusItem = document.activeElement.closest("li");
    }

    if (
      document.activeElement === this.search ||
      focusItem === null ||
      focusItem.previousSibling === null ||
      focusItem.previousSibling.tagName !== "LI"
    ) {
      this.focusItem(items[items.length - 1]);
    } else {
      this.focusItem(focusItem.previousSibling);
    }
  },

  moveFocusDown() {
    const items = this.el.querySelectorAll("li:not(.hidden)");

    if (items.length === 0) {
      return;
    }

    let focusItem = null;
    if (this.el.contains(document.activeElement)) {
      focusItem = document.activeElement.closest("li");
    }

    if (
      document.activeElement === this.search ||
      focusItem === null ||
      focusItem.nextElementSibling === null ||
      focusItem.nextElementSibling.tagName !== "LI"
    ) {
      this.focusItem(items[0]);
    } else {
      this.focusItem(focusItem.nextElementSibling);
    }
  },

  focusItem(item) {
    const target = item.querySelector("a, button, input, textarea")?.focus();
  },

  mounted() {
    this.abortController = new AbortController();

    this.delegate = document.querySelector(this.el.dataset.delegate);
    this.search = document.querySelector(this.el.dataset.search);

    this.search.addEventListener(
      "input",
      (event) => {
        this.updateFilter();
      },
      { signal: this.abortController.signal },
    );

    this.search.addEventListener(
      "keydown",
      (event) => {
        const { ctrlKey, metaKey, key } = event;

        if (!(ctrlKey || metaKey) || !(key === "j" || key == "k")) {
          return;
        }

        event.preventDefault();

        if (key === "j") {
          this.moveFocusDown();
        } else if (key === "k") {
          this.moveFocusUp();
        }
      },
      {
        signal: this.abortController.signal,
      },
    );

    this.el.addEventListener(
      "keydown",
      (event) => {
        switch (event.key) {
          case "j":
            this.moveFocusDown();
            break;

          case "k":
            this.moveFocusUp();
            break;

          case "/":
            setTimeout(() => {
              this.search.focus();
            }, 0);
            break;

          case "Enter":
            document.activeElement.click();
            break;
        }
      },
      {
        signal: this.abortController.signal,
      },
    );
    this.el.addEventListener(
      "click",
      () => {
        const popover = event.target.closest("[popover]");
        if (popover !== null) {
          popover.hidePopover();
        }
      },
      { signal: this.abortController.signal },
    );
  },

  destroyed() {
    this.abortController.abort();
  },
};
