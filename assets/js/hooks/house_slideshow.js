const HouseSlideshow = {
  mounted() {
    this.init();
  },

  updated() {
    this.cleanup();
    this.init();
  },

  destroyed() {
    this.cleanup();
  },

  init() {
    this.slides = Array.from(this.el.querySelectorAll('[data-slide]'));
    this.texts = Array.from(this.el.querySelectorAll('[data-text]'));
    this.bgLayers = Array.from(this.el.querySelectorAll('[data-bg]'));
    this.progressLines = Array.from(this.el.querySelectorAll('[data-progress]'));

    if (!this.slides.length) return;

    this.currentIndex = 0;
    this.duration = 5000; // 5 seconds per slide
    this.timer = null;
    this.animFrame = null;

    this.setActive(0);
    this.startProgress();
  },

  setActive(index) {
    this.slides.forEach((slide, i) => {
      const isCurrent = i === index;

      // Float Photo state
      if (isCurrent) {
        slide.style.opacity = '1';
        slide.style.transform = 'scale(1) translateY(0px)';
        slide.style.zIndex = '30';
      } else {
        slide.style.opacity = '0';
        slide.style.transform = 'scale(0.92) translateY(15px)';
        slide.style.zIndex = '10';
      }

      // Dynamic Glass Background state
      if (this.bgLayers[i]) {
        this.bgLayers[i].style.opacity = isCurrent ? '0.7' : '0';
      }

      // Top-Left Text Entry state (Slide in from top-left: -translate-x-12, -translate-y-8)
      if (this.texts[i]) {
        if (isCurrent) {
          this.texts[i].style.opacity = '1';
          this.texts[i].style.transform = 'translate(0px, 0px)';
          this.texts[i].style.pointerEvents = 'auto';
        } else {
          this.texts[i].style.opacity = '0';
          this.texts[i].style.transform = 'translate(-48px, -32px)';
          this.texts[i].style.pointerEvents = 'none';
        }
      }
    });
  },

  startProgress() {
    const startTime = performance.now();

    const step = (now) => {
      const elapsed = now - startTime;
      const progress = Math.min((elapsed / this.duration) * 100, 100);

      this.progressLines.forEach((line, i) => {
        if (i < this.currentIndex) {
          line.style.width = '100%';
        } else if (i === this.currentIndex) {
          line.style.width = `${progress}%`;
        } else {
          line.style.width = '0%';
        }
      });

      if (elapsed < this.duration) {
        this.animFrame = requestAnimationFrame(step);
      } else {
        this.next();
      }
    };

    this.animFrame = requestAnimationFrame(step);
  },

  next() {
    this.currentIndex = (this.currentIndex + 1) % this.slides.length;
    this.setActive(this.currentIndex);
    this.startProgress();
  },

  cleanup() {
    if (this.animFrame) cancelAnimationFrame(this.animFrame);
  }
};

export { HouseSlideshow };
export default HouseSlideshow;