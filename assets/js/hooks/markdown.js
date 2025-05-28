import morphdom from "morphdom";
import { marked } from "marked";

const isVisibleInViewport = (element) => {
  const rect = element.getBoundingClientRect();
  return (
    rect.top >= 0 &&
    rect.left >= 0 &&
    rect.bottom <=
      (window.innerHeight || document.documentElement.clientHeight) &&
    rect.right <= (window.innerWidth || document.documentElement.clientWidth)
  );
};

export default {
  renderCached(content, content_id) {
    if (!content_id) {
      return this.render(content);
    }

    const key = `message_${content_id}`;

    let cachedContent = localStorage.getItem(key);
    if (cachedContent === null) {
      cachedContent = { timestamp: new Date(), content: this.render(content) };
    } else {
      cachedContent = JSON.parse(cachedContent);
    }

    localStorage.setItem(key, JSON.stringify(cachedContent));

    return cachedContent.content;
  },

  render(content) {
    return marked.parse(content);
  },

  setContent(content) {
    const container = document.createElement("div");

    requestAnimationFrame(() => {
      container.innerHTML = content;
      morphdom(this.container, container);
      this.el.classList.remove("hidden");
      this.hidden = false;

      queueMicrotask(() => {
        const event = new CustomEvent(":message-loaded", {
          detail: {},
          bubbles: true,
        });
        this.el.dispatchEvent(event);
      });
    });
  },

  mounted() {
    this.container = document.createElement("div");
    this.hidden = true;

    if (
      this.el.dataset.role === "assistant" &&
      this.el.dataset.status === "processing"
    ) {
      let lastIndex = -1;
      let buffer = "";
      const id = this.el.dataset.messageId;

      this.handleEvent(`update-completion:${id}`, (data) => {
        data.chunks.forEach((chunk) => {
          if (chunk.index <= lastIndex) {
            return;
          } else if (chunk.index > lastIndex + 1) {
            console.log("Desync", lastIndex, chunk.index);
          }

          lastIndex = chunk.index;
          buffer += chunk.delta;
        });

        this.setContent(this.render(buffer));
      });

      this.handleEvent(`updated-message:${id}`, (data) => {
        if (data.status == "done") {
          buffer = "";
        }

        const content = this.renderCached(data.content, data.content_id);
        this.setContent(content);
      });
    }

    const visible = isVisibleInViewport(this.el);

    function setInitialContent() {
      const contentId = this.el.dataset.contentId;
      const rawContent = this.el.textContent;

      this.el.innerHTML = "";
      this.el.appendChild(this.container);

      const content = this.renderCached(rawContent, contentId);
      this.setContent(content);
    }

    if (visible) {
      setInitialContent.call(this);
    } else {
      queueMicrotask(setInitialContent.bind(this));
    }
  },
};
