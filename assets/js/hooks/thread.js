import morphdom from "morphdom";
import { marked } from "marked";

export default {
  updateMargin() {
    if (!this.lastUserMessage) {
      return;
    }

    let offsetHeight = this.lastUserMessage.offsetHeight;
    if (this.lastMessage !== this.lastUserMessage) {
      offsetHeight += this.lastMessage.offsetHeight;
    }

    this.margin = Math.max(0, this.scrollContainer.clientHeight - offsetHeight);
  },

  setMargin() {
    const el = document.getElementById("scroll-bottom");
    el.style.height = `max(0px, calc(${this.margin}px - 2.5rem))`;
  },

  mounted() {
    this.abortController = new AbortController();
    this.scrollContainer = document.getElementById("scroll-container");
    this.lastUserMessage = null;
    this.lastMessage = null;
    this.margin = 0;

    this.handleEvent("created-message", (data) => {
      this.lastMessage = document.getElementById(data.message_id);
      this.updateMargin();

      if (data.role === "user") {
        this.lastUserMessage = this.lastMessage;

        requestAnimationFrame(() => {
          this.setMargin();
          this.lastUserMessage.scrollIntoView({
            behavior: "smooth",
            block: "start",
          });
        });
      }
    });

    requestAnimationFrame(() => {
      this.scrollContainer.scrollTop = this.scrollContainer.scrollHeight;
    });

    let messageCount = parseInt(this.el.dataset.messageCount, 10) || 0;
    if (messageCount > 0) {
      this.el.addEventListener(
        ":message-loaded",
        () => {
          if (messageCount < 0 && this.lastUserMessage) {
            requestAnimationFrame(() => {
              this.updateMargin();
              this.setMargin();
            });
          }
          if (--messageCount === 0) {
            document.getElementById("scroll-bottom").scrollIntoView();
          }
        },
        { aign: this.abortController.signal },
      );
    }
  },

  destroyed() {
    this.abortController.abort();
  },

  updated() {
    this.setMargin();
    requestAnimationFrame(() => {
      this.updateMargin(this.lastUserMessage);
      this.setMargin();
    });
  },
};
