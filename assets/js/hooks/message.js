import DOMPurify from "dompurify";
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
  purge() {
    const threshold = new Date().getTime() - 86_400_00;

    Object.keys(localStorage).forEach((key) => {
      const value = localStorage.getItem(key);
      let data;

      try {
        data = JSON.parse(value);
      } catch {
        localStorage.removeItem(key);
      }

      if (!data.timestamp || data.timestamp < threshold) {
        localStorage.removeItem(key);
      }
    });
  },

  renderCached(content, contentId) {
    if (!contentId) {
      return this.render(content);
    }

    const key = `message:${this.cacheKey}:${contentId}`;
    const cachedValue = localStorage.getItem(key);

    const renderAndSet = (key, content) => {
      const rendered = this.render(content);
      localStorage.setItem(
        key,
        JSON.stringify({
          content: rendered,
          timestamp: new Date().getTime(),
        }),
      );

      return rendered;
    };

    if (cachedValue === null) {
      return renderAndSet(key, content);
    }

    let cachedData = null;
    try {
      cachedData = JSON.parse(cachedValue);
    } catch (e) {
      return renderAndSet(key, content);
    }

    const now = new Date().getTime();
    if (now - cachedData.timestamp > 86_400_000) {
      return renderAndSet(key, content);
    }

    return cachedData.content;
  },

  render(content) {
    return DOMPurify.sanitize(
      marked.parse(
        content.replace(/^[\u200B\u200C\u200D\u200E\u200F\uFEFF]/, ""),
      ),
    );
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
    this.cacheKey = this.el.dataset.messageCacheKey || "";

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

    queueMicrotask(() => {
      this.purge();
    });
  },
};
